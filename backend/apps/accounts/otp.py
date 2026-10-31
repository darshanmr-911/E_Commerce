import hashlib
import hmac
import re
import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import timezone

from apps.accounts.models import OtpChallenge
from apps.accounts.sms import SmsDeliveryError, send_otp_sms

OTP_LENGTH = 6
OTP_EXPIRY = timedelta(minutes=5)
OTP_RESEND_COOLDOWN = timedelta(seconds=30)
OTP_SEND_WINDOW = timedelta(hours=1)
OTP_MAX_SENDS_PER_WINDOW = 5
OTP_MAX_FAILED_ATTEMPTS = 5


class OtpRequestError(Exception):
    def __init__(self, code, retry_after_seconds=0):
        self.code = code
        self.retry_after_seconds = retry_after_seconds
        super().__init__(code)


class OtpVerificationError(Exception):
    def __init__(self, code, attempts_remaining=None):
        self.code = code
        self.attempts_remaining = attempts_remaining
        super().__init__(code)


def normalize_indian_phone(value):
    if not re.fullmatch(r"\+?[0-9\s()-]+", value.strip()):
        return None
    digits = re.sub(r"[^0-9]", "", value)
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    if len(digits) != 10 or digits[0] not in "6789":
        return None
    return f"+91{digits}"


def _digest_otp(phone, salt, code):
    key = getattr(settings, "OTP_HASH_KEY", settings.SECRET_KEY).encode("utf-8")
    message = f"otp:{phone}:{salt}:{code}".encode("utf-8")
    return hmac.new(key, message, hashlib.sha256).hexdigest()


def _digest_phone(phone):
    key = getattr(settings, "OTP_HASH_KEY", settings.SECRET_KEY).encode("utf-8")
    message = f"phone:{phone}".encode("utf-8")
    return hmac.new(key, message, hashlib.sha256).hexdigest()


def request_login_otp(phone):
    now = timezone.now()
    code = f"{secrets.randbelow(10**OTP_LENGTH):0{OTP_LENGTH}d}"
    salt = secrets.token_hex(16)
    phone_hash = _digest_phone(phone)
    challenge, _ = OtpChallenge.objects.get_or_create(phone_hash=phone_hash)
    with transaction.atomic():
        challenge = OtpChallenge.objects.select_for_update().get(pk=challenge.pk)
        if challenge.last_sent_at:
            cooldown_ends = challenge.last_sent_at + OTP_RESEND_COOLDOWN
            if now < cooldown_ends:
                retry_after = int((cooldown_ends - now).total_seconds()) + 1
                raise OtpRequestError("otp_cooldown", retry_after)

        if (
            challenge.send_window_started_at is None
            or now - challenge.send_window_started_at >= OTP_SEND_WINDOW
        ):
            challenge.send_window_started_at = now
            challenge.sends_in_window = 0
        if challenge.sends_in_window >= OTP_MAX_SENDS_PER_WINDOW:
            retry_after = int(
                (
                    challenge.send_window_started_at
                    + OTP_SEND_WINDOW
                    - now
                ).total_seconds()
            ) + 1
            raise OtpRequestError("otp_rate_limited", retry_after)

        challenge.last_sent_at = now
        challenge.sends_in_window += 1
        challenge.code_digest = ""
        challenge.salt = salt
        challenge.expires_at = None
        challenge.failed_attempts = 0
        challenge.updated_at = now
        challenge.save(
            update_fields=[
                "last_sent_at",
                "send_window_started_at",
                "sends_in_window",
                "code_digest",
                "salt",
                "expires_at",
                "failed_attempts",
                "updated_at",
            ]
        )

    try:
        send_otp_sms(phone, code)
    except SmsDeliveryError:
        OtpChallenge.objects.filter(pk=challenge.pk, salt=salt).update(salt="")
        raise

    sent_at = timezone.now()
    updated = OtpChallenge.objects.filter(pk=challenge.pk, salt=salt).update(
        code_digest=_digest_otp(phone, salt, code),
        expires_at=sent_at + OTP_EXPIRY,
        updated_at=sent_at,
    )
    if not updated:
        raise OtpRequestError("otp_superseded")
    return int(OTP_RESEND_COOLDOWN.total_seconds())


def verify_login_otp(phone, code):
    User = get_user_model()
    result = None
    failure = None
    now = timezone.now()

    with transaction.atomic():
        challenge = (
            OtpChallenge.objects.select_for_update()
            .filter(phone_hash=_digest_phone(phone))
            .first()
        )
        if challenge is None or not challenge.code_digest:
            failure = OtpVerificationError("otp_not_found")
        elif challenge.expires_at is None or challenge.expires_at <= now:
            challenge.code_digest = ""
            challenge.salt = ""
            challenge.expires_at = None
            challenge.save(update_fields=["code_digest", "salt", "expires_at"])
            failure = OtpVerificationError("otp_expired")
        elif challenge.failed_attempts >= OTP_MAX_FAILED_ATTEMPTS:
            failure = OtpVerificationError("otp_attempts_exceeded")
        elif not hmac.compare_digest(
            challenge.code_digest, _digest_otp(phone, challenge.salt, code)
        ):
            challenge.failed_attempts += 1
            if challenge.failed_attempts >= OTP_MAX_FAILED_ATTEMPTS:
                challenge.code_digest = ""
                challenge.salt = ""
                challenge.expires_at = None
                failure = OtpVerificationError("otp_attempts_exceeded")
            else:
                failure = OtpVerificationError(
                    "otp_invalid",
                    OTP_MAX_FAILED_ATTEMPTS - challenge.failed_attempts,
                )
            challenge.save(
                update_fields=[
                    "failed_attempts",
                    "code_digest",
                    "salt",
                    "expires_at",
                ]
            )
        else:
            challenge.code_digest = ""
            challenge.salt = ""
            challenge.expires_at = None
            challenge.save(update_fields=["code_digest", "salt", "expires_at"])
            result = User.objects.filter(phone=phone).first()
            if result is None:
                result = User.objects.create_user(
                    username=f"customer_{secrets.token_hex(12)}",
                    phone=phone,
                    role=User.Role.CUSTOMER,
                )
            elif result.role != User.Role.CUSTOMER or not result.is_active:
                failure = OtpVerificationError("account_not_eligible")
                result = None

    if failure:
        raise failure
    return result
