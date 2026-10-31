# FreshKart API v1

Base URL: `https://<host>/api/v1/`. JSON is used unless an image is uploaded;
owner product and profile uploads accept `multipart/form-data`. Protected
endpoints require `Authorization: Bearer <access-token>`.

## Authentication

- `POST auth/send-otp/` — `{ "phone": "9876543210" }` (or `+919876543210`).
  Valid Indian mobile numbers are normalized to `+91`. A successful response
  means the configured SMS provider accepted the request; it does not prove
  handset delivery. Returns `expires_in_seconds` and `resend_after_seconds`.
- `POST auth/verify-otp/` — `{ "phone": "9876543210", "code": "012345" }`.
  A valid, unexpired, unused code returns customer JWT access/refresh tokens.
  Unknown verified phone numbers are registered as customer accounts; existing
  owner numbers cannot receive customer tokens.
- OTPs expire after five minutes, are stored as keyed HMAC digests, allow five
  failed attempts, and enforce a 30-second resend cooldown and five sends per
  phone per hour. DRF also applies scoped send/verify IP throttles. Invalid
  phones return 400, incorrect/expired codes return 400, exhausted limits return
  429, and unconfigured or failed SMS delivery returns 503.
- `POST owner/login/` — `{ "identifier": "email-or-phone", "password": "..." }`
- `POST auth/customer/login/` — same request shape; only customer accounts are accepted.
- Both return `{ "access": "...", "refresh": "...", "role": "owner|customer" }`.
  Access tokens expire after 15 minutes. Refresh tokens expire after 7 days.
- Owner screens additionally require an active owner account and active shop.
  The API derives the shop from the authenticated user; owner IDs are never
  accepted from the client.

## Owner endpoints

- `GET owner/dashboard/` — product/order counts, low stock, paid sales today, five recent orders.
- `POST|GET owner/products/` — create/list own products. Supports `?search=`, `?category=`,
  `?available=true|false`, and `?ordering=name|-selling_price`.
- `GET|PATCH|DELETE owner/products/{id}/` — retrieve/update/archive a product.
  `DELETE` archives by disabling the product.
- `PATCH owner/products/{id}/availability/` — `{ "is_active": true|false }`.
  Manual activation is stored separately from stock. Purchase availability is
  `is_active && stock_quantity >= minimum_order_quantity`.
- `PATCH owner/products/{id}/stock/` — `{ "quantity_change": 5, "reason": "Restock" }`.
  Adjustment is atomic, cannot make stock negative, and writes stock history.
- Product writes use `category_id`, `name`, `description`, `selling_price`,
  `original_price`, `unit`, `stock_quantity` (create only), stock thresholds,
  `minimum_order_quantity`, `maximum_order_quantity`, and optional `image`.
  Images are JPEG/PNG/WebP, at most 5 MiB.
- `GET owner/inventory/?low_stock=true` — own inventory; stock changes are made
  through the product stock endpoint so movement history is always recorded.
- `GET owner/stock-history/?product={id}` — own recorded stock changes.
- `GET owner/orders/?status=new` — orders for the authenticated shop.
- `PATCH owner/orders/{id}/status/` — `{ "status": "accepted|rejected|preparing|ready|out_for_delivery|delivered", "reason": "..." }`.
  Rejections require a reason, dispatch/delivery require a verified payment, and
  illegal transitions return 400.
- `GET|PATCH owner/profile/` — shop and owner profile fields; owner role and
  account status are not writable.

## Customer endpoints

- `GET products/` and `GET products/{id}/` — public purchasable products only:
  active products from active shops/categories with stock at least the minimum
  order quantity.
- `GET categories/` — active categories.
- `POST orders/` — customer JWT required. Provide `delivery_address_snapshot`,
  `items: [{ "product_id": 1, "quantity": 2 }]`, optional `coupon_code` and
  `payment_method: "upi"`. Prices, coupon (FRESH10), delivery fee and stock are
  calculated and checked on the server.
  The transaction locks stock rows, snapshots product names/prices and creates
  a pending UPI payment; no payment is attempted.
- `GET orders/`, `GET orders/{id}/` — the authenticated customer's orders.
- `PATCH orders/{id}/cancel/` — cancel an eligible order; inventory is restored
  atomically and movement history is written.

JWT authorization, owner-shop scoping, input validation, database transactions,
and per-user/anonymous API throttles are enabled. Payment status remains pending
until a future verified gateway webhook is implemented. Do not mark an order
paid from a Flutter client.

SMS provider credentials are server-only. Configure `SMS_OTP_PROVIDER=msg91`
with `MSG91_AUTH_KEY` and `MSG91_OTP_TEMPLATE_ID`, or select the documented
`http_json` adapter. See the repository README for provider setup and template
requirements. `SMS_OTP_PROVIDER=disabled` is suitable only for local
development and does not issue codes or create sessions.

For production, set `DJANGO_DEBUG=false`, configure a strong random
`DJANGO_SECRET_KEY`, use PostgreSQL and HTTPS, set
`DJANGO_SECURE_SSL_REDIRECT=true`, and configure HSTS only after verifying that
the entire host is HTTPS-only.
