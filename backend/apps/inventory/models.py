from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models


class Inventory(models.Model):
    product = models.OneToOneField(
        "catalog.Product", on_delete=models.CASCADE, related_name="inventory"
    )
    stock_quantity = models.PositiveIntegerField(default=0)
    low_stock_threshold = models.PositiveIntegerField(default=5)
    minimum_order_quantity = models.PositiveIntegerField(default=1)
    maximum_order_quantity = models.PositiveIntegerField(default=50)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=models.Q(maximum_order_quantity__gte=models.F("minimum_order_quantity")),
                name="inventory_max_order_gte_min",
            )
        ]

    def clean(self):
        if self.maximum_order_quantity < self.minimum_order_quantity:
            raise ValidationError(
                {"maximum_order_quantity": "Must be at least the minimum order quantity."}
            )

    @property
    def is_low_stock(self):
        return self.stock_quantity <= self.low_stock_threshold


class StockMovement(models.Model):
    class MovementType(models.TextChoices):
        RESTOCK = "restock", "Restock"
        REDUCTION = "reduction", "Reduction"
        ADJUSTMENT = "adjustment", "Adjustment"
        ORDER = "order", "Order"
        CANCELLATION = "cancellation", "Order cancellation"

    product = models.ForeignKey(
        "catalog.Product", on_delete=models.PROTECT, related_name="stock_movements"
    )
    quantity_change = models.IntegerField()
    movement_type = models.CharField(max_length=16, choices=MovementType.choices)
    reason = models.CharField(max_length=240, blank=True)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="stock_movements"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["product", "-created_at"])]
