import os

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenBlacklistView, TokenRefreshView

from apps.accounts.views import (
    CustomerLoginView,
    OwnerLoginView,
    SendOtpView,
    VerifyOtpView,
)
from apps.catalog.views import CategoryViewSet, CustomerProductViewSet, OwnerProductViewSet
from apps.inventory.views import InventoryViewSet, StockHistoryView
from apps.orders.views import CustomerOrderViewSet, OwnerOrderViewSet
from apps.shops.views import OwnerDashboardView, OwnerProfileView

router = DefaultRouter()
router.register("owner/products", OwnerProductViewSet, basename="owner-products")
router.register("owner/inventory", InventoryViewSet, basename="owner-inventory")
router.register("owner/orders", OwnerOrderViewSet, basename="owner-orders")
router.register("products", CustomerProductViewSet, basename="products")
router.register("categories", CategoryViewSet, basename="categories")
router.register("orders", CustomerOrderViewSet, basename="customer-orders")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/owner/login/", OwnerLoginView.as_view(), name="owner-login"),
    path("api/v1/auth/customer/login/", CustomerLoginView.as_view(), name="customer-login"),
    path("api/v1/auth/send-otp/", SendOtpView.as_view(), name="send-otp"),
    path("api/v1/auth/verify-otp/", VerifyOtpView.as_view(), name="verify-otp"),
    path("api/v1/auth/token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("api/v1/auth/token/blacklist/", TokenBlacklistView.as_view(), name="token-blacklist"),
    path("api/v1/owner/dashboard/", OwnerDashboardView.as_view(), name="owner-dashboard"),
    path("api/v1/owner/profile/", OwnerProfileView.as_view(), name="owner-profile"),
    path("api/v1/owner/stock-history/", StockHistoryView.as_view(), name="stock-history"),
    path("api/v1/", include(router.urls)),
]

if settings.DEBUG and os.environ.get("STORAGE_BACKEND") != "s3":
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
