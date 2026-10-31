import json
import os
from urllib.parse import urlparse
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from django.conf import settings


class SmsDeliveryError(Exception):
    pass


def send_otp_sms(phone: str, code: str) -> None:
    provider = settings.SMS_OTP_PROVIDER
    if provider == "msg91":
        _send_with_msg91(phone, code)
        return
    if provider == "http_json":
        _send_with_http_json(phone, code)
        return
    raise SmsDeliveryError("SMS delivery is not configured on the server.")


def _send_with_msg91(phone: str, code: str) -> None:
    auth_key = os.environ.get("MSG91_AUTH_KEY", "")
    template_id = os.environ.get("MSG91_OTP_TEMPLATE_ID", "")
    if not auth_key or not template_id:
        raise SmsDeliveryError("The SMS provider is not fully configured.")

    variable = settings.MSG91_OTP_TEMPLATE_VARIABLE
    payload = {
        "template_id": template_id,
        "short_url": "0",
        "recipients": [
            {
                "mobiles": phone.removeprefix("+"),
                variable: code,
            }
        ],
    }
    _post_json(
        settings.MSG91_OTP_API_URL,
        payload,
        {"authkey": auth_key},
        response_success=lambda result: result.get("type") == "success",
    )


def _send_with_http_json(phone: str, code: str) -> None:
    endpoint = os.environ.get("SMS_HTTP_JSON_API_URL", "")
    token = os.environ.get("SMS_HTTP_JSON_API_TOKEN", "")
    if not endpoint or not token:
        raise SmsDeliveryError("The SMS provider is not fully configured.")

    _post_json(
        endpoint,
        {
            "phone": phone,
            "otp": code,
            "expires_in_minutes": settings.OTP_EXPIRY_MINUTES,
            "template_id": os.environ.get("SMS_HTTP_JSON_TEMPLATE_ID", ""),
        },
        {"authorization": f"Bearer {token}"},
        response_success=lambda result: result.get("success") is True,
    )


def _post_json(endpoint, payload, headers, response_success):
    if urlparse(endpoint).scheme != "https":
        raise SmsDeliveryError("The SMS provider endpoint must use HTTPS.")
    request = Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers={"content-type": "application/json", **headers},
        method="POST",
    )
    try:
        with urlopen(request, timeout=settings.SMS_PROVIDER_TIMEOUT_SECONDS) as response:
            if not 200 <= response.status < 300:
                raise SmsDeliveryError("The SMS provider rejected the request.")
            result = json.loads(response.read().decode("utf-8"))
    except SmsDeliveryError:
        raise
    except (HTTPError, URLError, TimeoutError, OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SmsDeliveryError("The SMS provider could not be reached.") from error

    if not isinstance(result, dict) or not response_success(result):
        raise SmsDeliveryError("The SMS provider did not accept the message.")
