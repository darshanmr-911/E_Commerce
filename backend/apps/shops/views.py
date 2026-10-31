from django.db.models import F, Q, Sum
from django.core.validators import RegexValidator
from django.utils import timezone
from rest_framework import serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsShopOwner
from apps.catalog.models import Product
from apps.inventory.models import Inventory
from apps.orders.models import Order
from apps.shops.models import Shop


class OwnerDashboardView(APIView):
    permission_classes = [IsAuthenticated, IsShopOwner]

    def get(self, request):
        shop = request.user.shop
        products = Product.objects.filter(shop=shop)
        orders = Order.objects.filter(shop=shop)
        today = timezone.localdate()
        return Response(
            {
                "total_products": products.count(),
                "available_products": products.filter(is_active=True)
                .filter(
                    inventory__stock_quantity__gte=F(
                        "inventory__minimum_order_quantity"
                    )
                )
                .count(),
                "unavailable_products": products.filter(
                    Q(is_active=False)
                    | Q(
                        inventory__stock_quantity__lt=F(
                            "inventory__minimum_order_quantity"
                        )
                    )
                ).count(),
                "low_stock_products": Inventory.objects.filter(
                    product__shop=shop,
                    product__is_active=True,
                    stock_quantity__lte=F("low_stock_threshold"),
                ).count(),
                "total_orders": orders.count(),
                "pending_orders": orders.filter(
                    status__in=[Order.Status.NEW, Order.Status.ACCEPTED, Order.Status.PREPARING]
                ).count(),
                "completed_orders": orders.filter(status=Order.Status.DELIVERED).count(),
                "today_sales": orders.filter(
                    created_at__date=today,
                    payment_status=Order.PaymentStatus.PAID,
                ).aggregate(total=Sum("total"))["total"]
                or 0,
                "recent_orders": [
                    {
                        "id": order.pk,
                        "order_status": order.status,
                        "total": order.total,
                        "created_at": order.created_at,
                    }
                    for order in orders.order_by("-created_at")[:5]
                ],
            }
        )
class OwnerProfileSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source="owner.get_full_name", read_only=True)
    owner_email = serializers.EmailField(source="owner.email", read_only=True)
    owner_phone = serializers.CharField(source="owner.phone", read_only=True)
    phone = serializers.CharField(
        validators=[
            RegexValidator(
                regex=r"^\+?[1-9]\d{9,14}$",
                message="Enter a valid phone number in international format.",
            )
        ]
    )

    class Meta:
        model = Shop
        fields = (
            "id",
            "owner_name",
            "owner_email",
            "owner_phone",
            "shop_name",
            "description",
            "logo",
            "address",
            "phone",
            "opening_hours",
            "delivery_service_area",
            "is_active",
        )
        read_only_fields = ("id", "is_active")


class OwnerProfileView(APIView):
    permission_classes = [IsAuthenticated, IsShopOwner]

    def get(self, request):
        return Response(OwnerProfileSerializer(request.user.shop).data)

    def patch(self, request):
        serializer = OwnerProfileSerializer(
            request.user.shop, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
