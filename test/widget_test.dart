import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_commerce/features/home/screens/home_screen.dart';
import 'package:e_commerce/main.dart';
import 'package:e_commerce/services/customer_api_client.dart';

class _MemoryTokenStore implements CustomerTokenStore {
  final Map<String, String> tokens = {};

  @override
  Future<String?> read(String key) async => tokens[key];

  @override
  Future<void> write(String key, String value) async => tokens[key] = value;

  @override
  Future<void> delete(String key) async => tokens.remove(key);
}

Future<_MemoryTokenStore> _pumpLoginApp(
  WidgetTester tester, {
  bool smsAccepted = true,
  bool otpAccepted = false,
}) async {
  final tokenStore = _MemoryTokenStore();
  final api = CustomerApiClient(
    client: MockClient((request) async {
      if (request.url.path.endsWith('/auth/send-otp/')) {
        return smsAccepted
            ? httpResponse({
                'detail': 'Accepted',
                'expires_in_seconds': 300,
                'resend_after_seconds': 30,
              }, 200)
            : httpResponse({
                'detail': 'The verification message could not be sent.',
              }, 503);
      }
      if (request.url.path.endsWith('/auth/verify-otp/')) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        return otpAccepted
            ? httpResponse({
                'access': 'test-access-token',
                'refresh': 'test-refresh-token',
                'role': 'customer',
              }, 200)
            : httpResponse({
                'code': 'otp_invalid',
                'detail': 'The verification code is incorrect.',
              }, 400);
      }
      return httpResponse({'detail': 'Unexpected test request.'}, 404);
    }),
    tokenStore: tokenStore,
  );
  await tester.pumpWidget(FreshKartApp(customerApi: api));
  return tokenStore;
}

http.Response httpResponse(Map<String, Object?> body, int statusCode) {
  return http.Response(jsonEncode(body), statusCode);
}

void main() {
  testWidgets('FreshKart launches on login instead of the shopping screens', (
    tester,
  ) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Login to get fresh products at your door.'),
      findsOneWidget,
    );
    expect(find.text('Verify Your Number'), findsNothing);
    expect(find.byKey(const ValueKey('homeSearchField')), findsNothing);
    expect(find.byKey(const ValueKey('product-Tomatoes')), findsNothing);
  });

  testWidgets('shows the FreshKart animated login screen', (tester) async {
    await _pumpLoginApp(tester);
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
    await _pumpLoginApp(tester);
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

    await _pumpLoginApp(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigates to OTP after a server-accepted send request', (
    tester,
  ) async {
    await _pumpLoginApp(tester);
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
    expect(find.text('The verification code is incorrect.'), findsOneWidget);
  });

  testWidgets('requires all six OTP digits before verification', (
    tester,
  ) async {
    await _pumpLoginApp(tester);
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
      await _pumpLoginApp(tester);
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
    await _pumpLoginApp(tester);
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
    await _pumpLoginApp(tester);
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

  testWidgets('SMS delivery failure keeps the customer on the login screen', (
    tester,
  ) async {
    await _pumpLoginApp(tester, smsAccepted: false);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );

    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('The verification message could not be sent.'),
      findsOneWidget,
    );
    expect(find.text('Verify Your Number'), findsNothing);
    expect(
      find.text('Login to get fresh products at your door.'),
      findsOneWidget,
    );
  });

  testWidgets('Home opens only after backend OTP verification succeeds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tokenStore = await _pumpLoginApp(tester, otpAccepted: true);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );
    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pumpAndSettle();

    expect(find.text('Verify Your Number'), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      await tester.enterText(
        find.byKey(ValueKey('otpDigit$index')),
        '${index + 1}',
      );
    }
    await tester.tap(find.byKey(const ValueKey('verifyOtpButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('homeSearchField')), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.text('Login to get fresh products at your door.'),
      findsNothing,
    );
    expect(tokenStore.tokens['freshkart_customer_access'], 'test-access-token');
    expect(
      tokenStore.tokens['freshkart_customer_refresh'],
      'test-refresh-token',
    );
  });
}
