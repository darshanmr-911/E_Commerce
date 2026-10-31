from django.conf import settings
from django.db import models


class Order(models.Model):
    class Status(models.TextChoices):
        NEW = "new", "New"
        ACCEPTED = "accepted", "Accepted"
        PREPARING = "preparing", "Preparing"
        READY = "ready", "Ready for dispatch"
        OUT_FOR_DELIVERY = "out_for_delivery", "Out for delivery"
        DELIVERED = "delivered", "Delivered"
        REJECTED = "rejected", "Rejected"
        CANCELLED = "cancelled", "Cancelled"

    class PaymentStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        PAID = "paid", "Paid"
        FAILED = "failed", "Failed"
        REFUNDED = "refunded", "Refunded"

    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="orders"
    )
    shop = models.ForeignKey("shops.Shop", on_delete=models.PROTECT, related_name="orders")
    delivery_address_snapshot = models.JSONField()
    subtotal = models.DecimalField(max_digits=12, decimal_places=2)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.NEW)
    payment_status = models.CharField(
        max_length=12, choices=PaymentStatus.choices, default=PaymentStatus.PENDING
    )
    rejection_reason = models.CharField(max_length=240, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["shop", "status", "-created_at"]),
            models.Index(fields=["customer", "-created_at"]),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(subtotal__gte=0), name="order_subtotal_nonnegative"
            ),
            models.CheckConstraint(
                condition=models.Q(delivery_fee__gte=0), name="order_delivery_nonnegative"
            ),
            models.CheckConstraint(
                condition=models.Q(discount__gte=0), name="order_discount_nonnegative"
            ),
            models.CheckConstraint(
                condition=models.Q(total__gte=0), name="order_total_nonnegative"
            ),
        ]


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey("catalog.Product", on_delete=models.PROTECT)
    product_name_snapshot = models.CharField(max_length=120)
    unit_price_snapshot = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.PositiveIntegerField()
    line_total = models.DecimalField(max_digits=12, decimal_places=2)


class Payment(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        PAID = "paid", "Paid"
        FAILED = "failed", "Failed"
        REFUNDED = "refunded", "Refunded"

    class Method(models.TextChoices):
        UPI = "upi", "UPI"

    order = models.ForeignKey(Order, on_delete=models.PROTECT, related_name="payments")
    payment_method = models.CharField(max_length=12, choices=Method.choices)
    gateway_reference = models.CharField(max_length=120, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    payment_status = models.CharField(max_length=12, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.CheckConstraint(condition=models.Q(amount__gt=0), name="payment_amount_positive")
        ]
