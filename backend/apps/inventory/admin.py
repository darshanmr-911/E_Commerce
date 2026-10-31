from django.contrib import admin

from apps.inventory.models import Inventory, StockMovement


@admin.register(Inventory)
class InventoryAdmin(admin.ModelAdmin):
    list_display = ("product", "stock_quantity", "low_stock_threshold", "updated_at")


@admin.register(StockMovement)
class StockMovementAdmin(admin.ModelAdmin):
    list_display = ("product", "quantity_change", "movement_type", "updated_by", "created_at")
    readonly_fields = ("product", "quantity_change", "movement_type", "reason", "updated_by", "created_at")
