from datetime import timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.accounts.models import OtpChallenge
from apps.accounts.sms import SmsDeliveryError
from apps.shops.models import Shop

User = get_user_model()


class OtpAuthenticationTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.owner = User.objects.create_user(
            username="otp-owner",
            phone="+919876543210",
            role=User.Role.OWNER,
        )
        Shop.objects.create(
            owner=self.owner,
            shop_name="OTP Test Shop",
            address="Bengaluru",
            phone=self.owner.phone,
        )
        self.customer = User.objects.create_user(
            username="otp-customer",
            phone="+919876543211",
            role=User.Role.CUSTOMER,
        )
        self.send_url = reverse("send-otp")
        self.verify_url = reverse("verify-otp")

    @patch("apps.accounts.otp.send_otp_sms")
    def test_customer_otp_issues_jwt_and_consumes_hashed_code(self, send_sms):
        sent = self.client.post(
            self.send_url, {"phone": "9876543211"}, format="json"
        )
        self.assertEqual(sent.status_code, 200, sent.data)
        code = send_sms.call_args.args[1]
        self.assertRegex(code, r"^\d{6}$")
        self.assertNotIn(code, str(sent.data))

        challenge = OtpChallenge.objects.get()
        self.assertNotIn("phone", {field.name for field in challenge._meta.fields})
        self.assertEqual(len(challenge.code_digest), 64)
        self.assertNotEqual(challenge.code_digest, code)
        self.assertGreater(challenge.expires_at, timezone.now())

        wrong_code = "000000" if code != "000000" else "111111"
        incorrect = self.client.post(
            self.verify_url,
            {"phone": "9876543211", "code": wrong_code},
            format="json",
        )
        self.assertEqual(incorrect.status_code, 400)
        self.assertEqual(incorrect.data["code"], "otp_invalid")
        challenge.refresh_from_db()
        self.assertEqual(challenge.failed_attempts, 1)

        verified = self.client.post(
            self.verify_url,
            {"phone": "+919876543211", "code": code},
            format="json",
        )
        self.assertEqual(verified.status_code, 200, verified.data)
        self.assertEqual(verified.data["role"], User.Role.CUSTOMER)
        self.assertIn("access", verified.data)
        self.assertIn("refresh", verified.data)
        challenge.refresh_from_db()
        self.assertEqual(challenge.code_digest, "")

        replayed = self.client.post(
            self.verify_url,
            {"phone": "9876543211", "code": code},
            format="json",
        )
        self.assertEqual(replayed.status_code, 400)
        self.assertEqual(replayed.data["code"], "otp_not_found")

    def test_send_otp_rejects_invalid_indian_phone_number(self):
        for phone in ("1234567890", "call me 9876543211", "987654321"):
            with self.subTest(phone=phone):
                response = self.client.post(
                    self.send_url, {"phone": phone}, format="json"
                )
                self.assertEqual(response.status_code, 400)

    @patch("apps.accounts.otp.send_otp_sms")
    def test_otp_resend_cooldown_and_hourly_phone_limit(self, send_sms):
        payload = {"phone": "9876543211"}
        self.assertEqual(
            self.client.post(self.send_url, payload, format="json").status_code,
            200,
        )

        cooldown = self.client.post(self.send_url, payload, format="json")
        self.assertEqual(cooldown.status_code, 429)
        self.assertEqual(cooldown.data["code"], "otp_cooldown")
        self.assertGreater(cooldown.data["retry_after_seconds"], 0)

        challenge = OtpChallenge.objects.get()
        for _ in range(4):
            challenge.last_sent_at = timezone.now() - timedelta(seconds=31)
            challenge.save(update_fields=["last_sent_at"])
            response = self.client.post(self.send_url, payload, format="json")
            self.assertEqual(response.status_code, 200, response.data)

        challenge.refresh_from_db()
        challenge.last_sent_at = timezone.now() - timedelta(seconds=31)
        challenge.save(update_fields=["last_sent_at"])
        limited = self.client.post(self.send_url, payload, format="json")
        self.assertEqual(limited.status_code, 429)
        self.assertEqual(limited.data["code"], "otp_rate_limited")

    @patch(
        "apps.accounts.otp.send_otp_sms",
        side_effect=SmsDeliveryError("provider unavailable"),
    )
    def test_sms_delivery_failure_does_not_issue_a_verifiable_code(self, _send_sms):
        response = self.client.post(
            self.send_url, {"phone": "9876543211"}, format="json"
        )
        self.assertEqual(response.status_code, 503)
        challenge = OtpChallenge.objects.get()
        self.assertEqual(challenge.code_digest, "")
        self.assertIsNone(challenge.expires_at)

        verify = self.client.post(
            self.verify_url,
            {"phone": "9876543211", "code": "123456"},
            format="json",
        )
        self.assertEqual(verify.status_code, 400)
        self.assertEqual(verify.data["code"], "otp_not_found")

    @patch("apps.accounts.otp.send_otp_sms")
    def test_expired_code_is_rejected_and_invalidated(self, _send_sms):
        self.client.post(
            self.send_url, {"phone": "9876543211"}, format="json"
        )
        challenge = OtpChallenge.objects.get()
        challenge.expires_at = timezone.now() - timedelta(seconds=1)
        challenge.save(update_fields=["expires_at"])

        response = self.client.post(
            self.verify_url,
            {"phone": "9876543211", "code": "123456"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.data["code"], "otp_expired")
        challenge.refresh_from_db()
        self.assertEqual(challenge.code_digest, "")

    @patch("apps.accounts.otp.send_otp_sms")
    def test_five_incorrect_codes_invalidate_the_challenge(self, send_sms):
        self.client.post(
            self.send_url, {"phone": "9876543211"}, format="json"
        )
        actual_code = send_sms.call_args.args[1]
        incorrect_code = "111111" if actual_code != "111111" else "222222"
        for attempt in range(5):
            response = self.client.post(
                self.verify_url,
                {"phone": "9876543211", "code": incorrect_code},
                format="json",
            )
            self.assertEqual(response.status_code, 429 if attempt == 4 else 400)
        challenge = OtpChallenge.objects.get()
        self.assertEqual(challenge.code_digest, "")

    @patch("apps.accounts.otp.send_otp_sms")
    def test_verified_new_phone_creates_customer_account(self, send_sms):
        self.client.post(self.send_url, {"phone": "9876543212"}, format="json")
        response = self.client.post(
            self.verify_url,
            {"phone": "9876543212", "code": send_sms.call_args.args[1]},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)
        self.assertTrue(
            User.objects.filter(
                phone="+919876543212", role=User.Role.CUSTOMER
            ).exists()
        )

    @patch("apps.accounts.otp.send_otp_sms")
    def test_owner_phone_cannot_receive_customer_jwt(self, send_sms):
        self.client.post(self.send_url, {"phone": "9876543210"}, format="json")
        response = self.client.post(
            self.verify_url,
            {"phone": "9876543210", "code": send_sms.call_args.args[1]},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.data["code"], "account_not_eligible")
        self.assertNotIn("access", response.data)
