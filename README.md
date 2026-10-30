# FreshKart

FreshKart is a Flutter grocery e-commerce app prototype. The phone-number
login navigates to an interactive OTP screen, but neither SMS delivery nor
authentication is connected.

## Run the app

From the project directory, run:

```sh
flutter pub get
flutter run
```

## Try the login screen

- Watch the logo, welcome content, and form animate into view on launch.
- Enter fewer than 10 digits and tap **Continue** to see inline validation.
- Enter 10 digits and tap **Continue** to open the OTP screen.
- Enter six digits, then tap **Verify** to see its loading state and explicit
  placeholder notice. No login or OTP verification is performed.
- Wait 30 seconds to enable **Resend OTP**; resending is also a UI-only
  placeholder and does not send an SMS.
- Open the keyboard and scroll the page if needed to reach the button or terms.

Run the widget tests with `flutter test`.
