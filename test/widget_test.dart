import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce/main.dart';

void main() {
  testWidgets('shows the FreshKart animated login screen', (tester) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();

    expect(find.text('FreshKart'), findsOneWidget);
    expect(
      find.text('Fresh groceries, delivered to your doorstep.'),
      findsOneWidget,
    );
    expect(
      find.text('Login to get fresh products at your door.'),
      findsOneWidget,
    );
    expect(find.text('+91'), findsOneWidget);
    expect(find.textContaining('Terms of Service'), findsOneWidget);
    expect(find.textContaining('Privacy Policy'), findsOneWidget);
  });

  testWidgets('validates the phone number before continuing', (tester) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '12345',
    );

    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a valid 10-digit mobile number.'),
      findsOneWidget,
    );
    expect(find.text('Verify Your Number'), findsNothing);
  });

  testWidgets('keeps the login screen scrollable with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigates to OTP after a valid number and shows placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );

    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    expect(find.text('Verify Your Number'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    expect(find.byKey(const ValueKey('otpDigit0')), findsOneWidget);
    expect(find.byKey(const ValueKey('otpDigit5')), findsOneWidget);

    for (var index = 0; index < 6; index++) {
      await tester.enterText(
        find.byKey(ValueKey('otpDigit$index')),
        '${index + 1}',
      );
    }
    expect(
      List.generate(
        6,
        (index) => tester
            .widget<TextField>(find.byKey(ValueKey('otpDigit$index')))
            .controller!
            .text,
      ),
      ['1', '2', '3', '4', '5', '6'],
    );
    await tester.pump();
    expect(find.text('6 digits entered'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('verifyOtpButton')));
    await tester.pump();
    expect(find.text('Verifying...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Temporary placeholder: OTP verification is not connected. No login has taken place.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('requires all six OTP digits before verification', (
    tester,
  ) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );
    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verifyOtpButton')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter all 6 digits.'), findsOneWidget);
    expect(find.text('Verifying...'), findsNothing);
  });

  testWidgets(
    'backspace on an empty OTP field returns focus to the previous digit',
    (tester) async {
      await tester.pumpWidget(const FreshKartApp());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('phoneNumberField')),
        '9876543210',
      );
      await tester.tap(find.byKey(const ValueKey('continueButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('otpDigit0')), '1');
      await tester.enterText(find.byKey(const ValueKey('otpDigit1')), '2');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('otpDigit1')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
    },
  );

  testWidgets('resend stays disabled until the 30-second countdown ends', (
    tester,
  ) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );
    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    final resendButton = tester.widget<TextButton>(
      find.byKey(const ValueKey('resendOtpButton')),
    );
    expect(resendButton.onPressed, isNull);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    final enabledResendButton = tester.widget<TextButton>(
      find.byKey(const ValueKey('resendOtpButton')),
    );
    expect(enabledResendButton.onPressed, isNotNull);
  });

  testWidgets('back button returns to the login screen', (tester) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );
    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('otpBackButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Login to get fresh products at your door.'),
      findsOneWidget,
    );
  });
}
