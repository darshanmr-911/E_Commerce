from decimal import Decimal

from rest_framework import serializers

from apps.orders.models import Order, OrderItem


class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = (
            "product",
            "product_name_snapshot",
            "unit_price_snapshot",
            "quantity",
            "line_total",
        )


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "delivery_address_snapshot",
            "subtotal",
            "delivery_fee",
            "discount",
            "total",
            "status",
            "payment_status",
            "rejection_reason",
            "items",
            "created_at",
        )
        read_only_fields = fields


class OrderCreateSerializer(serializers.Serializer):
    delivery_address_snapshot = serializers.DictField()
    coupon_code = serializers.CharField(max_length=32, required=False, allow_blank=True)
    payment_method = serializers.ChoiceField(choices=["upi"])
    items = serializers.ListField(
        child=serializers.DictField(), allow_empty=False, max_length=100
    )

    def to_internal_value(self, data):
        unknown = set(data) - set(self.fields)
        if unknown:
            raise serializers.ValidationError(
                {key: "Unknown order field." for key in sorted(unknown)}
            )
        return super().to_internal_value(data)

    def validate_items(self, items):
        parsed = []
        seen = set()
        for item in items:
            try:
                product_id = int(item["product_id"])
                quantity = int(item["quantity"])
            except (KeyError, TypeError, ValueError) as error:
                raise serializers.ValidationError(
                    "Each item needs an integer product_id and quantity."
                ) from error
            if product_id in seen:
                raise serializers.ValidationError("Each product may appear only once.")
            if quantity < 1:
                raise serializers.ValidationError("Quantities must be positive.")
            seen.add(product_id)
            parsed.append({"product_id": product_id, "quantity": quantity})
        return parsed

    def validate(self, attrs):
        if not attrs["delivery_address_snapshot"]:
            raise serializers.ValidationError({"delivery_address_snapshot": "Address is required."})
        coupon = attrs.get("coupon_code", "").strip().upper()
        if coupon not in {"", "FRESH10"}:
            raise serializers.ValidationError({"coupon_code": "This coupon is not valid."})
        attrs["coupon_code"] = coupon
        return attrs
