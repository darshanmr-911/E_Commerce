from django.conf import settings
from django.core.validators import RegexValidator
from django.db import models


class Shop(models.Model):
    owner = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="shop"
    )
    shop_name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    logo = models.ImageField(upload_to="shops/logos/", blank=True)
    address = models.TextField()
    phone = models.CharField(
        max_length=16,
        validators=[
            RegexValidator(
                regex=r"^\+?[1-9]\d{9,14}$",
                message="Enter a valid phone number in international format.",
            )
        ],
    )
    opening_hours = models.CharField(max_length=160, blank=True)
    delivery_service_area = models.CharField(max_length=300, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.shop_name
