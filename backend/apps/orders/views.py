from decimal import Decimal

from django.db import transaction
from django.db.models import F
from rest_framework import serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsCustomer, IsShopOwner
from apps.catalog.models import Product
from apps.inventory.models import Inventory, StockMovement
from apps.orders.models import Order, OrderItem, Payment
from apps.orders.serializers import OrderCreateSerializer, OrderSerializer

DELIVERY_FEE = Decimal("30.00")
FREE_DELIVERY_THRESHOLD = Decimal("500.00")


class OwnerOrderStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Order.Status.choices)
    reason = serializers.CharField(max_length=240, required=False, allow_blank=True)


class OwnerOrderViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, IsShopOwner]
    serializer_class = OrderSerializer

    def get_queryset(self):
        queryset = Order.objects.filter(shop=self.request.user.shop).prefetch_related("items")
        order_status = self.request.query_params.get("status")
        return queryset.filter(status=order_status) if order_status else queryset

    @action(detail=True, methods=["patch"], url_path="status")
    @transaction.atomic
    def update_status(self, request, pk=None):
        order = self.get_queryset().select_for_update().get(pk=pk)
        serializer = OwnerOrderStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        target = serializer.validated_data["status"]
        allowed = {
            Order.Status.NEW: {Order.Status.ACCEPTED, Order.Status.REJECTED},
            Order.Status.ACCEPTED: {Order.Status.PREPARING, Order.Status.CANCELLED},
            Order.Status.PREPARING: {Order.Status.READY, Order.Status.CANCELLED},
            Order.Status.READY: {Order.Status.OUT_FOR_DELIVERY, Order.Status.CANCELLED},
            Order.Status.OUT_FOR_DELIVERY: {Order.Status.DELIVERED},
        }
        if target not in allowed.get(order.status, set()):
            raise ValidationError({"status": f"Cannot move an order from {order.status} to {target}."})
        if target in {Order.Status.OUT_FOR_DELIVERY, Order.Status.DELIVERED} and (
            order.payment_status != Order.PaymentStatus.PAID
        ):
            raise ValidationError(
                {"payment_status": "A verified payment is required before dispatch or delivery."}
            )
        if target == Order.Status.REJECTED and not serializer.validated_data.get("reason", "").strip():
            raise ValidationError({"reason": "A reason is required to reject an order."})
        if target in {Order.Status.REJECTED, Order.Status.CANCELLED}:
            self._restore_inventory(order, request.user)
        order.status = target
        if target == Order.Status.REJECTED:
            order.rejection_reason = serializer.validated_data["reason"].strip()
        order.save(update_fields=["status", "rejection_reason", "updated_at"])
        return Response(OrderSerializer(order).data)

    @staticmethod
    def _restore_inventory(order, user):
        for item in order.items.select_related("product").order_by("product_id"):
            inventory = Inventory.objects.select_for_update().get(product=item.product)
            inventory.stock_quantity = F("stock_quantity") + item.quantity
            inventory.save(update_fields=["stock_quantity", "updated_at"])
            StockMovement.objects.create(
                product=item.product,
                quantity_change=item.quantity,
                movement_type=StockMovement.MovementType.CANCELLATION,
                reason=f"Order {order.pk} {order.status}",
                updated_by=user,
            )


class CustomerOrderViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsCustomer]
    http_method_names = ["get", "post", "patch", "head", "options"]

    def get_queryset(self):
        queryset = Order.objects.filter(customer=self.request.user).prefetch_related("items")
        return queryset

    def get_serializer_class(self):
        return OrderCreateSerializer if self.action == "create" else OrderSerializer

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        item_inputs = sorted(
            serializer.validated_data["items"], key=lambda item: item["product_id"]
        )
        product_ids = [item["product_id"] for item in item_inputs]
        products = list(
            Product.objects.select_for_update()
            .filter(
                pk__in=product_ids,
                is_active=True,
                shop__is_active=True,
                category__is_active=True,
            )
            .select_related("shop")
            .order_by("pk")
        )
        if len(products) != len(product_ids):
            raise ValidationError({"items": "One or more products are unavailable."})
        if len({product.shop_id for product in products}) != 1:
            raise ValidationError({"items": "An order can contain products from one shop only."})
        inventories = {
            inventory.product_id: inventory
            for inventory in Inventory.objects.select_for_update()
            .filter(product_id__in=product_ids)
            .order_by("product_id")
        }
        items_by_id = {item["product_id"]: item["quantity"] for item in item_inputs}
        subtotal = Decimal("0.00")
        order_rows = []
        for product in products:
            inventory = inventories[product.pk]
            quantity = items_by_id[product.pk]
            if (
                inventory.stock_quantity < quantity
                or quantity < inventory.minimum_order_quantity
                or quantity > inventory.maximum_order_quantity
            ):
                raise ValidationError(
                    {"items": f"Invalid quantity or insufficient stock for {product.name}."}
                )
            line_total = product.selling_price * quantity
            subtotal += line_total
            order_rows.append((product, inventory, quantity, line_total))
        coupon = serializer.validated_data["coupon_code"]
        if coupon and subtotal < Decimal("200.00"):
            raise ValidationError({"coupon_code": "FRESH10 requires an item subtotal of ₹200."})
        discount = (
            min(subtotal / Decimal("10"), Decimal("100.00")).quantize(Decimal("0.01"))
            if coupon == "FRESH10"
            else Decimal("0.00")
        )
        delivery_fee = (
            Decimal("0.00") if subtotal >= FREE_DELIVERY_THRESHOLD else DELIVERY_FEE
        )
        order = Order.objects.create(
            customer=request.user,
            shop=products[0].shop,
            delivery_address_snapshot=serializer.validated_data["delivery_address_snapshot"],
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            discount=discount,
            total=subtotal + delivery_fee - discount,
        )
        for product, inventory, quantity, line_total in order_rows:
            OrderItem.objects.create(
                order=order,
                product=product,
                product_name_snapshot=product.name,
                unit_price_snapshot=product.selling_price,
                quantity=quantity,
                line_total=line_total,
            )
            inventory.stock_quantity -= quantity
            inventory.save(update_fields=["stock_quantity", "updated_at"])
            StockMovement.objects.create(
                product=product,
                quantity_change=-quantity,
                movement_type=StockMovement.MovementType.ORDER,
                reason=f"Order {order.pk}",
                updated_by=request.user,
            )
        Payment.objects.create(
            order=order,
            payment_method=Payment.Method.UPI,
            amount=order.total,
            payment_status=Payment.Status.PENDING,
        )
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["patch"])
    @transaction.atomic
    def cancel(self, request, pk=None):
        order = self.get_queryset().select_for_update().get(pk=pk)
        if order.status not in {
            Order.Status.NEW,
            Order.Status.ACCEPTED,
            Order.Status.PREPARING,
        }:
            raise ValidationError({"status": "This order can no longer be cancelled."})
        if order.payment_status != Order.PaymentStatus.PENDING:
            raise ValidationError(
                {"payment_status": "Paid orders need a verified refund before cancellation."}
            )
        OwnerOrderViewSet._restore_inventory(order, request.user)
        order.status = Order.Status.CANCELLED
        order.save(update_fields=["status", "updated_at"])
        return Response(OrderSerializer(order).data)
