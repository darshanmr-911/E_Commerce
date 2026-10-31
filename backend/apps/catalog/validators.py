from pathlib import Path

from django.core.exceptions import ValidationError
from PIL import Image, UnidentifiedImageError


MAX_IMAGE_BYTES = 5 * 1024 * 1024
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def validate_product_image(upload):
    if upload.size > MAX_IMAGE_BYTES:
        raise ValidationError("Image must be 5 MB or smaller.")
    if upload.content_type not in ALLOWED_IMAGE_TYPES:
        raise ValidationError("Use a JPEG, PNG, or WebP image.")
    if Path(upload.name).suffix.lower() not in ALLOWED_IMAGE_EXTENSIONS:
        raise ValidationError("Use a JPEG, PNG, or WebP image.")
    try:
        image = Image.open(upload)
        image.verify()
    except (UnidentifiedImageError, OSError) as error:
        raise ValidationError("The uploaded file is not a valid image.") from error
    finally:
        upload.seek(0)
