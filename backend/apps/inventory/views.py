from rest_framework import generics, serializers, viewsets
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import IsShopOwner
from apps.inventory.models import Inventory, StockMovement
from apps.inventory.serializers import InventorySerializer


class InventoryViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, IsShopOwner]
    serializer_class = InventorySerializer

    def get_queryset(self):
        queryset = Inventory.objects.filter(product__shop=self.request.user.shop).select_related(
            "product", "product__category", "product__shop"
        )
        low_stock = self.request.query_params.get("low_stock")
        if low_stock == "true":
            queryset = queryset.filter(
                stock_quantity__lte=models_f("low_stock_threshold")
            )
        return queryset

class StockHistoryView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, IsShopOwner]

    class Serializer(serializers.ModelSerializer):
        product_name = serializers.CharField(source="product.name", read_only=True)
        updated_by = serializers.CharField(source="updated_by.get_full_name", read_only=True)

        class Meta:
            model = StockMovement
            fields = (
                "id",
                "product",
                "product_name",
                "quantity_change",
                "movement_type",
                "reason",
                "updated_by",
                "created_at",
            )

    serializer_class = Serializer

    def get_queryset(self):
        queryset = StockMovement.objects.filter(product__shop=self.request.user.shop)
        product_id = self.request.query_params.get("product")
        return queryset.filter(product_id=product_id) if product_id else queryset


def models_f(field_name):
    from django.db.models import F

    return F(field_name)
