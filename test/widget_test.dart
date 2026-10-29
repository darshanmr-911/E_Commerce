import 'package:flutter/material.dart';
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
    expect(
      find.text(
        'Authentication will be implemented in a later update. No login has taken place.',
      ),
      findsNothing,
    );
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

  testWidgets('shows a loading state then a clear authentication placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberField')),
      '9876543210',
    );

    await tester.tap(find.byKey(const ValueKey('continueButton')));
    await tester.pump();

    expect(find.text('Please wait...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Authentication will be implemented in a later update. No login has taken place.',
      ),
      findsOneWidget,
    );
  });
}
