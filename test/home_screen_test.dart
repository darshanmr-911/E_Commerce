import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce/widgets/bottom_navigation.dart';
import 'package:e_commerce/main.dart';

Future<void> _pumpHomeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const FreshKartApp());
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushReplacementNamed('/home');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'opens the home screen with local grocery categories and products',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpHomeScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('FreshKart'), findsOneWidget);
      expect(find.textContaining('👋'), findsOneWidget);
      expect(find.byKey(const ValueKey('homeSearchField')), findsOneWidget);
      expect(find.byKey(const ValueKey('promoCarousel')), findsOneWidget);
      expect(find.text('Shop by category'), findsOneWidget);
      expect(find.byKey(const ValueKey('category-Vegetables')), findsOneWidget);
      expect(find.byKey(const ValueKey('category-Household')), findsOneWidget);
      expect(find.text('Popular products'), findsOneWidget);
      expect(find.byKey(const ValueKey('product-Tomatoes')), findsOneWidget);
      expect(find.text('₹40/kg'), findsOneWidget);
      expect(
        find.text('Login to get fresh products at your door.'),
        findsNothing,
      );
      expect(find.text('Verify Your Number'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search filters sample products and can be cleared', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('homeSearchField')),
      'Bananas',
    );
    await tester.pumpAndSettle();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-Bananas')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-Tomatoes')), findsNothing);
    expect(find.byKey(const ValueKey('clearSearchButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clearSearchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Popular products'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-Tomatoes')), findsOneWidget);
  });

  testWidgets(
    'category selection opens matching products and bottom navigation works',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpHomeScreen(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('seeAllCategoriesButton')));
      await tester.pumpAndSettle();
      expect(find.text('Shop by Category'), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigation>(find.byType(BottomNavigation))
            .selectedIndex,
        1,
      );

      await tester.tap(find.byKey(const ValueKey('category-Fruits')));
      await tester.pumpAndSettle();

      expect(find.text('Fruits picks'), findsOneWidget);
      expect(find.byKey(const ValueKey('product-bananas')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-Tomatoes')), findsNothing);
      expect(
        find.byKey(const ValueKey('category-products-fruits')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<BottomNavigation>(find.byType(BottomNavigation))
            .selectedIndex,
        1,
      );

      await tester.tap(find.byKey(const ValueKey('navigation-Orders')));
      await tester.pumpAndSettle();
      expect(find.text('Your orders'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('navigation-Profile')));
      await tester.pumpAndSettle();
      expect(find.text('Your profile'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('navigation-Home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('promoCarousel')), findsOneWidget);
    },
  );

  testWidgets('category search filters, clears, and shows an empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('navigation-Categories')));
    await tester.pumpAndSettle();

    expect(find.text('Shop by Category'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-Frozen Foods')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('categorySearchField')),
      'fruit',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-Fruits')), findsOneWidget);
    expect(find.byKey(const ValueKey('category-Vegetables')), findsNothing);
    expect(
      find.byKey(const ValueKey('clearCategorySearchButton')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('clearCategorySearchButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('category-Vegetables')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('categorySearchField')),
      'no-match',
    );
    await tester.pumpAndSettle();
    expect(find.text('No categories found'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('clearEmptyCategorySearchButton')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('category-Fruits')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'products can be added, favourited and removed from the sample cart',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpHomeScreen(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('add-Tomatoes')));
      await tester.tap(find.byKey(const ValueKey('add-Tomatoes')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('addToCartButton')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('favorite-Tomatoes')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove Tomatoes from favourites'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('navigation-Cart')));
      await tester.pumpAndSettle();
      expect(find.text('My Shopping Cart'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);
      expect(find.byKey(const ValueKey('proceedToCheckout')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('remove-cart-tomatoes')));
      await tester.pumpAndSettle();
      expect(find.text('Your cart is waiting'), findsOneWidget);
    },
  );

  testWidgets('home scrolls to the product section without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('homeScroll')),
      const Offset(0, -540),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('product-Tomatoes')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home fits a compact Android phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('category-Personal Care')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('product-Tomatoes')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('promotional banner advances automatically', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    expect(find.text('Freshness at your doorstep!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Good food, better days.'), findsOneWidget);
  });
}
