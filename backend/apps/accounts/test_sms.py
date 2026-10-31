import json
import os
from unittest.mock import patch

from django.test import SimpleTestCase, override_settings

from apps.accounts.sms import SmsDeliveryError, send_otp_sms


class SmsProviderTests(SimpleTestCase):
    @override_settings(
        SMS_OTP_PROVIDER="msg91",
        MSG91_OTP_API_URL="https://sms.example.test/api/flow",
        MSG91_OTP_TEMPLATE_VARIABLE="VAR1",
        OTP_EXPIRY_MINUTES=5,
        SMS_PROVIDER_TIMEOUT_SECONDS=3,
    )
    @patch.dict(
        os.environ,
        {
            "MSG91_AUTH_KEY": "server-only-test-key",
            "MSG91_OTP_TEMPLATE_ID": "approved-template",
        },
    )
    @patch("apps.accounts.sms.urlopen")
    def test_msg91_flow_uses_server_credentials_and_otp_template(self, urlopen):
        response = urlopen.return_value.__enter__.return_value
        response.status = 200
        response.read.return_value = b'{"type":"success","request_id":"abc"}'

        send_otp_sms("+919876543210", "084201")

        request = urlopen.call_args.args[0]
        body = json.loads(request.data)
        self.assertEqual(body["template_id"], "approved-template")
        self.assertEqual(body["recipients"][0]["mobiles"], "919876543210")
        self.assertEqual(body["recipients"][0]["VAR1"], "084201")
        self.assertEqual(request.get_header("Authkey"), "server-only-test-key")
        self.assertNotIn("server-only-test-key", request.data.decode())
        self.assertEqual(urlopen.call_args.kwargs["timeout"], 3)

    @override_settings(
        SMS_OTP_PROVIDER="msg91",
        MSG91_OTP_API_URL="https://sms.example.test/api/flow",
        MSG91_OTP_TEMPLATE_VARIABLE="VAR1",
        SMS_PROVIDER_TIMEOUT_SECONDS=3,
    )
    @patch.dict(os.environ, {"MSG91_AUTH_KEY": "", "MSG91_OTP_TEMPLATE_ID": ""})
    def test_msg91_requires_credentials_and_template(self):
        with self.assertRaises(SmsDeliveryError):
            send_otp_sms("+919876543210", "123456")

    @override_settings(
        SMS_OTP_PROVIDER="http_json",
        SMS_PROVIDER_TIMEOUT_SECONDS=3,
        OTP_EXPIRY_MINUTES=5,
    )
    @patch.dict(
        os.environ,
        {
            "SMS_HTTP_JSON_API_URL": "https://sms.example.test/send",
            "SMS_HTTP_JSON_API_TOKEN": "server-only-token",
            "SMS_HTTP_JSON_TEMPLATE_ID": "otp-template",
        },
    )
    @patch("apps.accounts.sms.urlopen")
    def test_http_json_adapter_requires_explicit_provider_acceptance(self, urlopen):
        response = urlopen.return_value.__enter__.return_value
        response.status = 200
        response.read.return_value = b'{"success":true}'

        send_otp_sms("+919876543210", "123456")
        request = urlopen.call_args.args[0]
        self.assertEqual(
            json.loads(request.data),
            {
                "phone": "+919876543210",
                "otp": "123456",
                "expires_in_minutes": 5,
                "template_id": "otp-template",
            },
        )
        self.assertEqual(
            request.get_header("Authorization"), "Bearer server-only-token"
        )

        response.read.return_value = b'{"success":false}'
        with self.assertRaises(SmsDeliveryError):
            send_otp_sms("+919876543210", "123456")

    @override_settings(
        SMS_OTP_PROVIDER="http_json",
        SMS_PROVIDER_TIMEOUT_SECONDS=3,
        OTP_EXPIRY_MINUTES=5,
    )
    @patch.dict(
        os.environ,
        {
            "SMS_HTTP_JSON_API_URL": "http://sms.example.test/send",
            "SMS_HTTP_JSON_API_TOKEN": "server-only-token",
        },
    )
    def test_provider_credentials_are_not_sent_over_insecure_http(self):
        with self.assertRaisesMessage(SmsDeliveryError, "must use HTTPS"):
            send_otp_sms("+919876543210", "123456")
