from django.db import transaction
from rest_framework import serializers

from apps.catalog.models import Category, Product
from apps.inventory.models import Inventory, StockMovement


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "description", "image", "is_active")


class ProductSerializer(serializers.ModelSerializer):
    category_id = serializers.PrimaryKeyRelatedField(
        source="category", queryset=Category.objects.filter(is_active=True)
    )
    category_name = serializers.CharField(source="category.name", read_only=True)
    stock_quantity = serializers.IntegerField(min_value=0, required=False)
    low_stock_threshold = serializers.IntegerField(min_value=0, required=False)
    minimum_order_quantity = serializers.IntegerField(min_value=1, required=False)
    maximum_order_quantity = serializers.IntegerField(min_value=1, required=False)
    is_active = serializers.BooleanField(required=False, default=True)
    is_available = serializers.BooleanField(read_only=True)
    low_stock = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = (
            "id",
            "category_id",
            "category_name",
            "name",
            "description",
            "image",
            "selling_price",
            "original_price",
            "unit",
            "is_active",
            "is_available",
            "stock_quantity",
            "low_stock_threshold",
            "minimum_order_quantity",
            "maximum_order_quantity",
            "low_stock",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def get_low_stock(self, product):
        return product.inventory.stock_quantity <= product.inventory.low_stock_threshold

    def to_representation(self, instance):
        data = super().to_representation(instance)
        inventory = instance.inventory
        data["stock_quantity"] = inventory.stock_quantity
        data["low_stock_threshold"] = inventory.low_stock_threshold
        data["minimum_order_quantity"] = inventory.minimum_order_quantity
        data["maximum_order_quantity"] = inventory.maximum_order_quantity
        return data

    def validate(self, attrs):
        selling = attrs.get("selling_price", getattr(self.instance, "selling_price", None))
        original = attrs.get("original_price", getattr(self.instance, "original_price", None))
        if selling is not None and original is not None and original < selling:
            raise serializers.ValidationError(
                {"original_price": "Original price must be at least the selling price."}
            )
        inventory = self.instance.inventory if self.instance is not None else None
        minimum = attrs.get(
            "minimum_order_quantity",
            inventory.minimum_order_quantity if inventory is not None else 1,
        )
        maximum = attrs.get(
            "maximum_order_quantity",
            inventory.maximum_order_quantity if inventory is not None else 50,
        )
        if maximum < minimum:
            raise serializers.ValidationError(
                {"maximum_order_quantity": "Maximum order quantity must be at least minimum."}
            )
        if self.instance is not None and "stock_quantity" in attrs:
            raise serializers.ValidationError(
                {"stock_quantity": "Use the stock adjustment endpoint to change inventory."}
            )
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        stock = validated_data.pop("stock_quantity", 0)
        threshold = validated_data.pop("low_stock_threshold", 5)
        minimum = validated_data.pop("minimum_order_quantity", 1)
        maximum = validated_data.pop("maximum_order_quantity", 50)
        validated_data["shop"] = self.context["request"].user.shop
        product = Product.objects.create(**validated_data)
        Inventory.objects.create(
            product=product,
            stock_quantity=stock,
            low_stock_threshold=threshold,
            minimum_order_quantity=minimum,
            maximum_order_quantity=maximum,
        )
        if stock:
            StockMovement.objects.create(
                product=product,
                quantity_change=stock,
                movement_type=StockMovement.MovementType.RESTOCK,
                reason="Initial stock",
                updated_by=self.context["request"].user,
            )
        return product

    @transaction.atomic
    def update(self, instance, validated_data):
        inventory_values = {
            "low_stock_threshold",
            "minimum_order_quantity",
            "maximum_order_quantity",
        }
        values = {
            key: validated_data.pop(key)
            for key in list(validated_data)
            if key in inventory_values
        }
        product = super().update(instance, validated_data)
        if values:
            inventory = Inventory.objects.select_for_update().get(product=product)
            for key, value in values.items():
                setattr(inventory, key, value)
            inventory.full_clean()
            inventory.save()
        return product


class PublicProductSerializer(serializers.ModelSerializer):
    category_id = serializers.IntegerField(read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)
    is_available = serializers.BooleanField(read_only=True)
    stock_quantity = serializers.IntegerField(
        source="inventory.stock_quantity", read_only=True
    )
    minimum_order_quantity = serializers.IntegerField(
        source="inventory.minimum_order_quantity", read_only=True
    )
    maximum_order_quantity = serializers.IntegerField(
        source="inventory.maximum_order_quantity", read_only=True
    )

    class Meta:
        model = Product
        fields = (
            "id",
            "category_id",
            "category_name",
            "name",
            "description",
            "image",
            "selling_price",
            "original_price",
            "unit",
            "is_available",
            "stock_quantity",
            "minimum_order_quantity",
            "maximum_order_quantity",
            "created_at",
            "updated_at",
        )
