from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.otp import (
    OtpRequestError,
    OtpVerificationError,
    request_login_otp,
    verify_login_otp,
)
from apps.accounts.serializers import (
    LoginSerializer,
    OtpPhoneSerializer,
    TokenPairSerializer,
    VerifyOtpSerializer,
)
from apps.accounts.sms import SmsDeliveryError


class RoleLoginView(APIView):
    permission_classes = [AllowAny]
    throttle_scope = "anon"
    role = None

    def post(self, request):
        serializer = LoginSerializer(
            data=request.data, context={"role": self.role}
        )
        serializer.is_valid(raise_exception=True)
        return Response(TokenPairSerializer.for_user(serializer.validated_data["user"]))


class OwnerLoginView(RoleLoginView):
    role = User.Role.OWNER


class CustomerLoginView(RoleLoginView):
    role = User.Role.CUSTOMER


class SendOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "otp_send"

    def post(self, request):
        serializer = OtpPhoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            retry_after = request_login_otp(serializer.validated_data["phone"])
        except OtpRequestError as error:
            return Response(
                {
                    "code": error.code,
                    "detail": (
                        "Please wait before requesting another code."
                        if error.code == "otp_cooldown"
                        else "Too many verification codes were requested. Try again later."
                    ),
                    "retry_after_seconds": error.retry_after_seconds,
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        except SmsDeliveryError:
            return Response(
                {
                    "code": "sms_delivery_failed",
                    "detail": (
                        "The verification message could not be sent. "
                        "Please try again later."
                    ),
                    "retry_after_seconds": 30,
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response(
            {
                "detail": "The verification code was accepted by the SMS provider.",
                "expires_in_seconds": 300,
                "resend_after_seconds": retry_after,
            },
            status=status.HTTP_200_OK,
        )


class VerifyOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "otp_verify"

    def post(self, request):
        serializer = VerifyOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user = verify_login_otp(
                serializer.validated_data["phone"],
                serializer.validated_data["code"],
            )
        except OtpVerificationError as error:
            details = {
                "otp_not_found": "Request a new verification code.",
                "otp_expired": "This verification code has expired. Request a new one.",
                "otp_invalid": "The verification code is incorrect.",
                "otp_attempts_exceeded": "Too many incorrect attempts. Request a new code.",
                "account_not_eligible": "This phone number cannot sign in as a customer.",
            }
            response = {"code": error.code, "detail": details[error.code]}
            if error.attempts_remaining is not None:
                response["attempts_remaining"] = error.attempts_remaining
            response_status = (
                status.HTTP_429_TOO_MANY_REQUESTS
                if error.code == "otp_attempts_exceeded"
                else status.HTTP_400_BAD_REQUEST
            )
            return Response(response, status=response_status)
        return Response(TokenPairSerializer.for_user(user))
