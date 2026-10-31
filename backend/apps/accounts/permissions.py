from rest_framework.permissions import BasePermission

from apps.accounts.models import User


class IsShopOwner(BasePermission):
    message = "A shop-owner account is required."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == User.Role.OWNER
            and hasattr(request.user, "shop")
            and request.user.shop.is_active
        )


class IsCustomer(BasePermission):
    message = "A customer account is required."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == User.Role.CUSTOMER
        )
