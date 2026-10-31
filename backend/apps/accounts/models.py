from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import Q
from django.db.models.functions import Lower
from django.utils import timezone


class User(AbstractUser):
    class Role(models.TextChoices):
        CUSTOMER = "customer", "Customer"
        OWNER = "owner", "Shop owner"

    email = models.EmailField(null=True, blank=True)
    phone = models.CharField(max_length=16, unique=True, null=True, blank=True)
    role = models.CharField(max_length=12, choices=Role.choices, default=Role.CUSTOMER)

    class Meta(AbstractUser.Meta):
        verbose_name = "user"
        verbose_name_plural = "users"
        constraints = [
            models.UniqueConstraint(
                Lower("email"),
                condition=Q(email__isnull=False) & ~Q(email=""),
                name="unique_nonempty_user_email_ci",
            )
        ]

    def __str__(self):
        return self.email or self.phone or self.username


class OtpChallenge(models.Model):
    phone_hash = models.CharField(max_length=64, unique=True)
    code_digest = models.CharField(max_length=64, blank=True)
    salt = models.CharField(max_length=32, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    last_sent_at = models.DateTimeField(null=True, blank=True)
    send_window_started_at = models.DateTimeField(null=True, blank=True)
    sends_in_window = models.PositiveSmallIntegerField(default=0)
    failed_attempts = models.PositiveSmallIntegerField(default=0)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        indexes = [models.Index(fields=["expires_at"])]
