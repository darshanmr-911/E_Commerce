from django.contrib import admin

from apps.orders.models import Order, OrderItem, Payment


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ("product", "product_name_snapshot", "unit_price_snapshot", "quantity", "line_total")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "customer", "shop", "status", "payment_status", "total", "created_at")
    list_filter = ("status", "payment_status", "shop")
    inlines = [OrderItemInline]


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ("order", "payment_method", "amount", "payment_status", "created_at")
    readonly_fields = ("order", "payment_method", "gateway_reference", "amount", "payment_status", "created_at")
