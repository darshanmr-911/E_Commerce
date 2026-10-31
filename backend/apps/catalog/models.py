from decimal import Decimal

from django.core.validators import MinValueValidator
from django.db import models

from apps.catalog.validators import validate_product_image


class Category(models.Model):
    name = models.CharField(max_length=80, unique=True)
    description = models.CharField(max_length=240, blank=True)
    image = models.ImageField(upload_to="categories/", blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "categories"

    def __str__(self):
        return self.name


class Product(models.Model):
    class Unit(models.TextChoices):
        KG = "kg", "Kilogram"
        G = "g", "Gram"
        LITRE = "litre", "Litre"
        ML = "ml", "Millilitre"
        PACKET = "packet", "Packet"
        DOZEN = "dozen", "Dozen"
        PIECE = "piece", "Piece"

    shop = models.ForeignKey("shops.Shop", on_delete=models.PROTECT, related_name="products")
    category = models.ForeignKey(
        Category, on_delete=models.PROTECT, related_name="products"
    )
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    image = models.ImageField(
        upload_to="products/", blank=True, validators=[validate_product_image]
    )
    selling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
    )
    original_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
    )
    unit = models.CharField(max_length=8, choices=Unit.choices)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        indexes = [
            models.Index(fields=["shop", "is_active"]),
            models.Index(fields=["category", "is_active"]),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(selling_price__gt=0), name="product_price_positive"
            ),
            models.CheckConstraint(
                condition=models.Q(original_price__gt=0),
                name="product_original_price_positive",
            ),
            models.CheckConstraint(
                condition=models.Q(selling_price__lte=models.F("original_price")),
                name="product_selling_lte_original",
            ),
        ]

    @property
    def is_available(self):
        inventory = self.inventory
        return (
            self.is_active
            and inventory.stock_quantity >= inventory.minimum_order_quantity
        )

    def __str__(self):
        return self.name
