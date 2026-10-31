# FreshKart

FreshKart is a Flutter grocery customer app with a separate shop-owner
workspace and a Django REST Framework API. The customer app uses sample data by
default; the owner workspace always authenticates against the API.

## Run the Django API and PostgreSQL

1. Copy `backend/.env.example` to `backend/.env`. Replace the secret key and
   database password with long, unique values. Keep this file private; it is
   ignored by Git.
2. Start the API and PostgreSQL:

   ```sh
   docker compose -f backend/compose.yaml --env-file backend/.env up --build
   ```

3. In another terminal, seed the standard 12 categories:

   ```sh
   docker compose -f backend/compose.yaml --env-file backend/.env exec api python manage.py seed_categories
   ```

4. Create an owner account and its shop. The password is prompted securely:

   ```sh
   docker compose -f backend/compose.yaml --env-file backend/.env exec api \
     python manage.py create_shop_owner \
     --username owner1 --email owner@example.com --phone +919876543210 \
     --first-name Asha --shop-name "FreshKart Local" --address "Bengaluru"
   ```

5. Customer accounts are created on the first successful phone OTP verification.
   Existing customer accounts with the verified phone number are signed in.

The database and uploaded development media persist in Docker volumes. For
production, configure PostgreSQL, S3-compatible image storage, a 50-character
random secret, explicit non-local allowed hosts, and HTTPS redirect before
setting `DJANGO_DEBUG=false`. The API refuses to start with missing or unsafe
production settings. Only enable HSTS once every relevant host is HTTPS-only. See
[backend/API.md](./backend/API.md) for all endpoints and request shapes.

## Run the Flutter app

```sh
flutter pub get
flutter run
```

In the default mode, the existing customer experience uses local sample
products. To connect the customer catalog, order flow, and history to the
backend on an Android emulator:

```sh
flutter run \
  --dart-define=FRESHKART_USE_BACKEND=true \
  --dart-define=FRESHKART_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For a physical device or iOS, set `FRESHKART_API_BASE_URL` to a reachable HTTPS
API URL. The owner sign-in entry is on the customer Profile tab; owner
navigation and secure token storage are separate from customer navigation.

## Customer SMS OTP configuration

The login screen calls the Django OTP endpoints; it does not generate or verify
codes locally. In development, SMS is disabled until a provider is configured,
and the API returns a delivery error instead of pretending a message was sent.
Provider credentials belong only in the private `backend/.env` file or your
deployment secret manager, never in Flutter `--dart-define` values or source
control.

For MSG91:

1. Create and activate an India-compliant SMS template with the required DLT
   entity/sender/template approvals. Put the six-digit code in the first
   variable (or configure `MSG91_OTP_TEMPLATE_VARIABLE` to match the template).
2. Set `SMS_OTP_PROVIDER=msg91`, `MSG91_AUTH_KEY`, and
   `MSG91_OTP_TEMPLATE_ID` in `backend/.env`. The server uses MSG91's Flow API
   over HTTPS; the auth key is sent only in the server-side request header.
3. Restart the API and test delivery with a permitted phone number. An accepted
   provider response means only that the provider accepted the request; it
   does not confirm handset delivery.

Alternatively, `SMS_OTP_PROVIDER=http_json` uses an HTTPS gateway adapter. Set
`SMS_HTTP_JSON_API_URL` and `SMS_HTTP_JSON_API_TOKEN` server-side. The endpoint
must accept JSON containing `phone`, `otp`, `expires_in_minutes`, and
`template_id`, and return `{"success": true}` only when it accepts the request.
For another provider with a different API contract, implement an adapter in
`backend/apps/accounts/sms.py`; do not put its credentials in the app.

OTP codes expire after five minutes, have a 30-second resend cooldown and a
five-per-hour per-phone send limit, and are stored as keyed HMAC digests. The
API also rate-limits send and verify requests by IP. Set a random
`OTP_HASH_KEY` in the server environment, distinct from other credentials.
After a valid server verification the API returns customer JWTs, which Flutter
stores with secure storage before navigating to Home. A provider must be
configured and externally tested for real SMS delivery; automated tests mock
provider responses and do not send SMS.

## Tests

```sh
flutter analyze
flutter test
```

Backend tests can run against the local SQLite test database:

```sh
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
DJANGO_SECRET_KEY=local-test-only-change-this DJANGO_DEBUG=true \
  .venv/bin/python manage.py test config apps.accounts apps.catalog apps.orders
```

For PostgreSQL-backed tests, use the same `DB_*` settings as the API service.

UPI gateway integration and verified payment callbacks are intentionally not
implemented. Backend orders begin in `pending` payment state, and the API blocks
dispatch/delivery until a future trusted payment integration marks them paid.
