from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from PIL import Image
from rest_framework.test import APITestCase
from io import BytesIO

from apps.catalog.models import Category, Product
from apps.inventory.models import Inventory, StockMovement
from apps.shops.models import Shop


User = get_user_model()


def image_file(name="test.png", color="green"):
    buffer = BytesIO()
    Image.new("RGB", (4, 4), color=color).save(buffer, format="PNG")
    return SimpleUploadedFile(name, buffer.getvalue(), content_type="image/png")


class CatalogApiTests(APITestCase):
    def setUp(self):
        self.owner = User.objects.create_user(
            username="owner", password="Secure-test-Password-27!", role=User.Role.OWNER
        )
        self.shop = Shop.objects.create(
            owner=self.owner, shop_name="Owner Shop", address="Bengaluru", phone="9876543210"
        )
        self.other_owner = User.objects.create_user(
            username="other", password="Secure-test-Password-27!", role=User.Role.OWNER
        )
        self.other_shop = Shop.objects.create(
            owner=self.other_owner, shop_name="Other Shop", address="Mysuru", phone="9876543211"
        )
        self.category = Category.objects.create(name="Vegetables")
        self.product = Product.objects.create(
            shop=self.shop,
            category=self.category,
            name="Tomato",
            selling_price=Decimal("40.00"),
            original_price=Decimal("45.00"),
            unit=Product.Unit.KG,
            image=image_file(),
        )
        self.inventory = Inventory.objects.create(
            product=self.product,
            stock_quantity=8,
            low_stock_threshold=2,
            minimum_order_quantity=1,
            maximum_order_quantity=10,
        )
        self.owner_products = "/api/v1/owner/products/"

    def tearDown(self):
        self.product.image.delete(save=False)

    def test_customer_listing_only_returns_active_in_stock_products(self):
        response = self.client.get("/api/v1/products/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["name"] for item in response.data["results"]], ["Tomato"])
        self.inventory.stock_quantity = 0
        self.inventory.save()
        self.assertEqual(self.client.get("/api/v1/products/").data["results"], [])
        self.inventory.stock_quantity = 4
        self.inventory.save()
        self.product.is_active = False
        self.product.save()
        self.assertEqual(self.client.get("/api/v1/products/").data["results"], [])

    def test_owner_can_upload_product_and_cannot_see_other_shop_products(self):
        self.client.force_authenticate(self.owner)
        response = self.client.post(
            self.owner_products,
            {
                "category_id": self.category.pk,
                "name": "Carrot",
                "description": "Fresh carrots",
                "selling_price": "50.00",
                "original_price": "55.00",
                "unit": "kg",
                "stock_quantity": 6,
                "low_stock_threshold": 2,
                "minimum_order_quantity": 1,
                "maximum_order_quantity": 12,
                "image": image_file("carrot.png"),
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["stock_quantity"], 6)
        self.assertEqual(response.data["is_available"], True, response.data)
        self.assertEqual(StockMovement.objects.filter(product_id=response.data["id"]).count(), 1)

        self.client.force_authenticate(self.other_owner)
        self.assertEqual(self.client.get(self.owner_products).data["results"], [])
        self.assertEqual(
            self.client.get(f"{self.owner_products}{self.product.pk}/").status_code, 404
        )

    def test_product_image_and_price_validation(self):
        self.client.force_authenticate(self.owner)
        response = self.client.post(
            self.owner_products,
            {
                "category_id": self.category.pk,
                "name": "Invalid",
                "selling_price": "60.00",
                "original_price": "50.00",
                "unit": "kg",
                "image": SimpleUploadedFile(
                    "not-image.png", b"not an image", content_type="image/png"
                ),
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Product.objects.filter(name="Invalid").count(), 0)

    def test_availability_and_locked_stock_adjustments(self):
        self.client.force_authenticate(self.owner)
        base = f"{self.owner_products}{self.product.pk}/"
        response = self.client.patch(
            f"{base}availability/", {"is_active": False}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["is_available"])

        response = self.client.patch(
            f"{base}stock/",
            {"quantity_change": -8, "reason": "Inventory sold"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["stock_quantity"], 0)
        self.assertFalse(response.data["is_available"])
        response = self.client.patch(
            f"{base}stock/",
            {"quantity_change": -1, "reason": "Invalid reduction"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        response = self.client.patch(
            f"{base}stock/",
            {"quantity_change": 5, "reason": "Replenished"},
            format="json",
        )
        self.assertEqual(response.data["stock_quantity"], 5)
        self.assertFalse(response.data["is_available"])
        self.assertEqual(StockMovement.objects.filter(product=self.product).count(), 2)

    def test_owner_product_edit_archive_and_minimum_stock_availability(self):
        self.client.force_authenticate(self.owner)
        url = f"{self.owner_products}{self.product.pk}/"
        edited = self.client.patch(
            url, {"selling_price": "38.50", "original_price": "40.00"}, format="json"
        )
        self.assertEqual(edited.status_code, 200)
        self.assertEqual(edited.data["selling_price"], "38.50")

        self.inventory.minimum_order_quantity = 9
        self.inventory.save()
        self.product.refresh_from_db()
        self.assertFalse(self.product.is_available)
        self.assertEqual(self.client.get("/api/v1/products/").data["results"], [])

        archived = self.client.delete(url)
        self.assertEqual(archived.status_code, 204)
        self.product.refresh_from_db()
        self.assertFalse(self.product.is_active)

    def test_unauthenticated_owner_product_access_is_rejected(self):
        response = self.client.get(self.owner_products)
        self.assertEqual(response.status_code, 401)
