from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from apps.accounts.models import User


@admin.register(User)
class FreshKartUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (("FreshKart", {"fields": ("phone", "role")}),)
    list_display = ("username", "email", "phone", "role", "is_active")
    list_filter = ("role", "is_active")
