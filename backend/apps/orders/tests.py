from decimal import Decimal

from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase

from apps.catalog.models import Category, Product
from apps.inventory.models import Inventory, StockMovement
from apps.orders.models import Order
from apps.shops.models import Shop


User = get_user_model()


class OrderApiTests(APITestCase):
    def setUp(self):
        self.owner = User.objects.create_user(
            username="owner", password="Secure-test-Password-27!", role=User.Role.OWNER
        )
        self.shop = Shop.objects.create(
            owner=self.owner, shop_name="Owner Shop", address="Bengaluru", phone="9876543210"
        )
        self.customer = User.objects.create_user(
            username="customer", password="Secure-test-Password-27!"
        )
        self.category = Category.objects.create(name="Vegetables")
        self.product = Product.objects.create(
            shop=self.shop,
            category=self.category,
            name="Onion",
            selling_price=Decimal("35.00"),
            original_price=Decimal("40.00"),
            unit=Product.Unit.KG,
        )
        self.inventory = Inventory.objects.create(
            product=self.product,
            stock_quantity=5,
            low_stock_threshold=2,
            minimum_order_quantity=2,
            maximum_order_quantity=5,
        )
        self.payload = {
            "delivery_address_snapshot": {
                "name": "Asha Rao",
                "mobile": "9876543210",
                "line1": "12 Market Road",
                "city": "Bengaluru",
                "pin_code": "560001",
            },
            "payment_method": "upi",
            "items": [{"product_id": self.product.pk, "quantity": 2}],
        }

    def test_customer_order_reserves_stock_and_starts_payment_pending(self):
        self.client.force_authenticate(self.customer)
        response = self.client.post("/api/v1/orders/", self.payload, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        order = Order.objects.get(pk=response.data["id"])
        self.assertEqual(order.subtotal, Decimal("70.00"))
        self.assertEqual(order.total, Decimal("100.00"))
        self.assertEqual(order.delivery_fee, Decimal("30.00"))
        self.assertEqual(order.payment_status, Order.PaymentStatus.PENDING)
        self.inventory.refresh_from_db()
        self.assertEqual(self.inventory.stock_quantity, 3)
        self.assertEqual(StockMovement.objects.filter(product=self.product).count(), 1)

    def test_simultaneous_order_attempt_cannot_oversell(self):
        self.client.force_authenticate(self.customer)
        payload = {**self.payload, "items": [{"product_id": self.product.pk, "quantity": 4}]}
        self.assertEqual(self.client.post("/api/v1/orders/", payload, format="json").status_code, 201)
        response = self.client.post("/api/v1/orders/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.inventory.refresh_from_db()
        self.assertEqual(self.inventory.stock_quantity, 1)
        self.assertEqual(Order.objects.count(), 1)

    def test_order_respects_product_minimum_and_maximum_quantities(self):
        self.client.force_authenticate(self.customer)
        below_minimum = {
            **self.payload,
            "items": [{"product_id": self.product.pk, "quantity": 1}],
        }
        self.assertEqual(
            self.client.post("/api/v1/orders/", below_minimum, format="json").status_code,
            400,
        )
        above_maximum = {
            **self.payload,
            "items": [{"product_id": self.product.pk, "quantity": 6}],
        }
        self.assertEqual(
            self.client.post("/api/v1/orders/", above_maximum, format="json").status_code,
            400,
        )

    def test_client_cannot_override_price_delivery_or_discount(self):
        self.client.force_authenticate(self.customer)
        payload = {**self.payload, "discount": "70.00", "delivery_fee": "0.00"}
        response = self.client.post("/api/v1/orders/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Order.objects.count(), 0)

    def test_owner_status_transitions_and_customer_cancellation_restore_stock(self):
        self.client.force_authenticate(self.customer)
        created = self.client.post("/api/v1/orders/", self.payload, format="json")
        order_id = created.data["id"]

        self.client.force_authenticate(self.owner)
        status_url = f"/api/v1/owner/orders/{order_id}/status/"
        invalid = self.client.patch(
            status_url, {"status": Order.Status.DELIVERED}, format="json"
        )
        self.assertEqual(invalid.status_code, 400)

        rejected_without_reason = self.client.patch(
            status_url, {"status": Order.Status.REJECTED}, format="json"
        )
        self.assertEqual(rejected_without_reason.status_code, 400)
        accepted = self.client.patch(
            status_url, {"status": Order.Status.ACCEPTED}, format="json"
        )
        self.assertEqual(accepted.status_code, 200)
        self.assertEqual(accepted.data["status"], Order.Status.ACCEPTED)

        self.client.force_authenticate(self.customer)
        cancelled = self.client.patch(
            f"/api/v1/orders/{order_id}/cancel/", {}, format="json"
        )
        self.assertEqual(cancelled.status_code, 200)
        self.inventory.refresh_from_db()
        self.assertEqual(self.inventory.stock_quantity, 5)
        self.assertEqual(
            StockMovement.objects.filter(
                product=self.product,
                movement_type=StockMovement.MovementType.CANCELLATION,
            ).count(),
            1,
        )

    def test_owner_cannot_dispatch_or_deliver_an_unpaid_order(self):
        self.client.force_authenticate(self.customer)
        created = self.client.post("/api/v1/orders/", self.payload, format="json")
        status_url = f"/api/v1/owner/orders/{created.data['id']}/status/"
        self.client.force_authenticate(self.owner)
        for target in (
            Order.Status.ACCEPTED,
            Order.Status.PREPARING,
            Order.Status.READY,
        ):
            response = self.client.patch(
                status_url, {"status": target}, format="json"
            )
            self.assertEqual(response.status_code, 200)
        for target in (Order.Status.OUT_FOR_DELIVERY, Order.Status.DELIVERED):
            response = self.client.patch(
                status_url, {"status": target}, format="json"
            )
            self.assertEqual(response.status_code, 400)
