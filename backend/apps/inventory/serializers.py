from rest_framework import serializers

from apps.catalog.serializers import ProductSerializer
from apps.inventory.models import Inventory


class InventorySerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)

    class Meta:
        model = Inventory
        fields = (
            "product",
            "stock_quantity",
            "low_stock_threshold",
            "minimum_order_quantity",
            "maximum_order_quantity",
            "is_low_stock",
            "updated_at",
        )


class StockAdjustmentSerializer(serializers.Serializer):
    quantity_change = serializers.IntegerField()
    reason = serializers.CharField(max_length=240, allow_blank=False)

    def validate_quantity_change(self, value):
        if value == 0:
            raise serializers.ValidationError("Stock adjustment must not be zero.")
        return value
