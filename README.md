# FreshKart

FreshKart is a Flutter grocery e-commerce app prototype with an interactive
sample grocery home screen. The phone-number login and OTP screens remain
available, but neither SMS delivery nor authentication is connected.

## Run the app

From the project directory, run:

```sh
flutter pub get
flutter run
```

## Try the home screen

- Browse the rotating grocery promotions and eight category cards.
- Search the local sample products, or use **Add** and the favourite controls.
- Use the bottom navigation to view categories, the sample cart, orders, and
  profile placeholders. Checkout and backend services are not connected.

The existing login remains available at the `/login` route. Its OTP screen is
still a UI-only placeholder and does not authenticate or send SMS.

Run the widget tests with `flutter test`.
