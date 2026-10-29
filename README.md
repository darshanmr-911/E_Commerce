# FreshKart

FreshKart is a Flutter grocery e-commerce app prototype. Day 1 is limited to
the animated phone-number login interface; it does not connect to an
authentication service or submit the phone number.

## Run the app

From the project directory, run:

```sh
flutter pub get
flutter run
```

## Try the login screen

- Watch the logo, welcome content, and form animate into view on launch.
- Enter fewer than 10 digits and tap **Continue** to see inline validation.
- Enter 10 digits and tap **Continue** to see the loading animation and the
  placeholder notice. No login or OTP is performed.
- Open the keyboard and scroll the page if needed to reach the button or terms.

Run the widget tests with `flutter test`.
