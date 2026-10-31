from django.contrib import admin

from apps.shops.models import Shop


@admin.register(Shop)
class ShopAdmin(admin.ModelAdmin):
    list_display = ("shop_name", "owner", "phone", "is_active")
    search_fields = ("shop_name", "owner__username", "phone")
