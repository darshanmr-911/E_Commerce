from collections.abc import Mapping
from urllib.parse import urlparse

from django.core.exceptions import ImproperlyConfigured


_REQUIRED_DATABASE_SETTINGS = ("DB_NAME", "DB_USER", "DB_PASSWORD")
_REQUIRED_STORAGE_SETTINGS = (
    "AWS_STORAGE_BUCKET_NAME",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
)
_LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1", "10.0.2.2"}


def validate_production_environment(environ: Mapping[str, str]) -> None:
    if environ.get("DJANGO_DEBUG", "false").lower() == "true":
        return

    errors = []
    secret_key = environ.get("DJANGO_SECRET_KEY", "")
    if len(secret_key) < 50:
        errors.append("DJANGO_SECRET_KEY must contain at least 50 characters")
    otp_hash_key = environ.get("OTP_HASH_KEY", "")
    if len(otp_hash_key) < 50:
        errors.append("OTP_HASH_KEY must contain at least 50 characters")
    elif otp_hash_key == secret_key:
        errors.append("OTP_HASH_KEY must be different from DJANGO_SECRET_KEY")

    missing_database_settings = [
        name for name in _REQUIRED_DATABASE_SETTINGS if not environ.get(name)
    ]
    if missing_database_settings:
        errors.append(
            "PostgreSQL must be configured with "
            + ", ".join(missing_database_settings)
        )

    if environ.get("STORAGE_BACKEND") != "s3":
        errors.append("STORAGE_BACKEND must be s3-compatible in production")
    else:
        missing_storage_settings = [
            name for name in _REQUIRED_STORAGE_SETTINGS if not environ.get(name)
        ]
        if missing_storage_settings:
            errors.append(
                "S3-compatible media storage must be configured with "
                + ", ".join(missing_storage_settings)
            )

    hosts = {
        host.strip().lower()
        for host in environ.get("DJANGO_ALLOWED_HOSTS", "").split(",")
        if host.strip()
    }
    if not hosts or "*" in hosts or hosts <= _LOCAL_HOSTS:
        errors.append(
            "DJANGO_ALLOWED_HOSTS must contain an explicit non-local host and no wildcard"
        )

    if environ.get("DJANGO_SECURE_SSL_REDIRECT", "true").lower() != "true":
        errors.append("DJANGO_SECURE_SSL_REDIRECT must be enabled in production")

    provider = environ.get("SMS_OTP_PROVIDER", "disabled").lower()
    if provider == "msg91":
        if not environ.get("MSG91_AUTH_KEY"):
            errors.append("MSG91_AUTH_KEY is required for SMS_OTP_PROVIDER=msg91")
        if not environ.get("MSG91_OTP_TEMPLATE_ID"):
            errors.append(
                "MSG91_OTP_TEMPLATE_ID is required for SMS_OTP_PROVIDER=msg91"
            )
    elif provider == "http_json":
        endpoint = environ.get("SMS_HTTP_JSON_API_URL", "")
        if not endpoint:
            errors.append(
                "SMS_HTTP_JSON_API_URL is required for SMS_OTP_PROVIDER=http_json"
            )
        elif urlparse(endpoint).scheme != "https":
            errors.append("SMS_HTTP_JSON_API_URL must use HTTPS")
        if not environ.get("SMS_HTTP_JSON_API_TOKEN"):
            errors.append(
                "SMS_HTTP_JSON_API_TOKEN is required for SMS_OTP_PROVIDER=http_json"
            )
    else:
        errors.append(
            "SMS_OTP_PROVIDER must be configured as msg91 or http_json in production"
        )

    if errors:
        raise ImproperlyConfigured(
            "Invalid production configuration: " + "; ".join(errors)
        )
