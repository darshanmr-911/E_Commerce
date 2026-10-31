from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User
from apps.accounts.otp import normalize_indian_phone


class LoginSerializer(serializers.Serializer):
    identifier = serializers.CharField(max_length=254)
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate(self, attrs):
        identifier = attrs["identifier"].strip()
        user_model = get_user_model()
        user = user_model.objects.filter(email__iexact=identifier).first()
        if user is None:
            user = user_model.objects.filter(phone=identifier).first()
        if user is None:
            user = user_model.objects.filter(username__iexact=identifier).first()
        if (
            user is None
            or not user.is_active
            or not user.check_password(attrs["password"])
            or user.role != self.context["role"]
        ):
            raise serializers.ValidationError(
                {"detail": "Invalid credentials or account role."}
            )
        if user.role == User.Role.OWNER and (
            not hasattr(user, "shop") or not user.shop.is_active
        ):
            raise serializers.ValidationError(
                {"detail": "This owner account has no active shop."}
            )
        attrs["user"] = user
        return attrs


class OtpPhoneSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

    def validate_phone(self, value):
        phone = normalize_indian_phone(value)
        if phone is None:
            raise serializers.ValidationError(
                "Enter a valid 10-digit Indian mobile number."
            )
        return phone


class VerifyOtpSerializer(OtpPhoneSerializer):
    code = serializers.RegexField(r"^\d{6}$", max_length=6, min_length=6)


class TokenPairSerializer(serializers.Serializer):
    @staticmethod
    def for_user(user):
        refresh = RefreshToken.for_user(user)
        refresh["role"] = user.role
        return {
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "role": user.role,
        }
