from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase

from apps.shops.models import Shop


User = get_user_model()


class AuthenticationTests(APITestCase):
    def setUp(self):
        self.owner = User.objects.create_user(
            username="owner",
            email="owner@example.test",
            phone="+919876543210",
            password="Secure-test-Password-27!",
            role=User.Role.OWNER,
        )
        Shop.objects.create(
            owner=self.owner, shop_name="FreshKart Local", address="Bengaluru", phone=self.owner.phone
        )
        self.customer = User.objects.create_user(
            username="customer",
            email="customer@example.test",
            password="Secure-test-Password-27!",
        )

    def test_owner_login_issues_role_claim_and_customer_cannot_login_as_owner(self):
        response = self.client.post(
            reverse("owner-login"),
            {"identifier": self.owner.phone, "password": "Secure-test-Password-27!"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["role"], User.Role.OWNER)
        self.assertIn("access", response.data)

        rejected = self.client.post(
            reverse("owner-login"),
            {"identifier": self.customer.email, "password": "Secure-test-Password-27!"},
        )
        self.assertEqual(rejected.status_code, 400)
        self.assertNotIn("access", rejected.data)

    def test_customer_token_cannot_access_owner_dashboard(self):
        response = self.client.post(
            reverse("customer-login"),
            {"identifier": self.customer.email, "password": "Secure-test-Password-27!"},
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        dashboard = self.client.get("/api/v1/owner/dashboard/")
        self.assertEqual(dashboard.status_code, 403)

    def test_owner_without_active_shop_cannot_login(self):
        self.owner.shop.is_active = False
        self.owner.shop.save(update_fields=["is_active"])
        response = self.client.post(
            reverse("owner-login"),
            {"identifier": self.owner.email, "password": "Secure-test-Password-27!"},
        )
        self.assertEqual(response.status_code, 400)
