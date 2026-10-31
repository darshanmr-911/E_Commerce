from django.contrib import admin

from apps.catalog.models import Category, Product


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active")
    search_fields = ("name",)
    list_filter = ("is_active",)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("name", "shop", "category", "selling_price", "is_active")
    search_fields = ("name", "shop__shop_name")
    list_filter = ("category", "is_active")
