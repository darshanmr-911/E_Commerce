from django.db import transaction
from django.db.models import F, Q
from rest_framework import filters, serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsShopOwner
from apps.catalog.models import Category, Product
from apps.catalog.serializers import (
    CategorySerializer,
    ProductSerializer,
    PublicProductSerializer,
)
from apps.inventory.models import Inventory, StockMovement


class StockAdjustmentSerializer(serializers.Serializer):
    quantity_change = serializers.IntegerField()
    reason = serializers.CharField(max_length=240, allow_blank=False)


class CustomerProductViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [AllowAny]
    serializer_class = PublicProductSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name", "description", "category__name"]
    ordering_fields = ["selling_price", "name", "created_at"]
    ordering = ["name"]

    def get_queryset(self):
        return (
            Product.objects.filter(
                is_active=True,
                shop__is_active=True,
                category__is_active=True,
                inventory__stock_quantity__gte=F(
                    "inventory__minimum_order_quantity"
                ),
            )
            .select_related("category", "shop", "inventory")
        )


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [AllowAny]
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer


class OwnerProductViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsShopOwner]
    serializer_class = ProductSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name", "description", "category__name"]
    ordering_fields = ["name", "selling_price", "updated_at"]
    ordering = ["name"]

    def get_queryset(self):
        queryset = Product.objects.filter(shop=self.request.user.shop).select_related(
            "category", "shop", "inventory"
        )
        category_id = self.request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        available = self.request.query_params.get("available")
        if available == "true":
            queryset = queryset.filter(
                is_active=True,
                inventory__stock_quantity__gte=F(
                    "inventory__minimum_order_quantity"
                ),
            )
        elif available == "false":
            queryset = queryset.filter(
                models_q_not_available()
            )
        return queryset

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active", "updated_at"])

    @action(detail=True, methods=["patch"])
    def availability(self, request, pk=None):
        product = self.get_object()
        serializer = AvailabilitySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        product.is_active = serializer.validated_data["is_active"]
        product.save(update_fields=["is_active", "updated_at"])
        return Response(self.get_serializer(product).data)

    @action(detail=True, methods=["patch"])
    @transaction.atomic
    def stock(self, request, pk=None):
        product = self.get_object()
        inventory = Inventory.objects.select_for_update().get(product=product)
        serializer = StockAdjustmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        change = serializer.validated_data["quantity_change"]
        new_stock = inventory.stock_quantity + change
        if change == 0:
            raise ValidationError({"quantity_change": "Stock adjustment must not be zero."})
        if new_stock < 0:
            raise ValidationError({"quantity_change": "Stock cannot become negative."})
        inventory.stock_quantity = new_stock
        inventory.save(update_fields=["stock_quantity", "updated_at"])
        StockMovement.objects.create(
            product=product,
            quantity_change=change,
            movement_type=(
                StockMovement.MovementType.RESTOCK
                if change > 0
                else StockMovement.MovementType.REDUCTION
            ),
            reason=serializer.validated_data["reason"],
            updated_by=request.user,
        )
        product.refresh_from_db()
        return Response(self.get_serializer(product).data)


def models_q_not_available():
    return Q(is_active=False) | Q(
        inventory__stock_quantity__lt=F("inventory__minimum_order_quantity")
    )


class AvailabilitySerializer(serializers.Serializer):
    is_active = serializers.BooleanField()
