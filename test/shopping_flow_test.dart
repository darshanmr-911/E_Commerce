import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce/features/home/data/home_sample_data.dart';
import 'package:e_commerce/main.dart';
import 'package:e_commerce/models/address.dart';
import 'package:e_commerce/models/product.dart';
import 'package:e_commerce/services/cart_service.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openCategory(WidgetTester tester, String categoryKey) async {
  await tester.pumpWidget(const FreshKartApp());
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushReplacementNamed('/home');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const ValueKey('seeAllCategoriesButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('category-$categoryKey')));
  await tester.pumpAndSettle();
}

void main() {
  group('product listing and details', () {
    testWidgets('filters, sorts, switches view, and toggles favourites', (
      tester,
    ) async {
      _setPhoneViewport(tester);
      await _openCategory(tester, 'Vegetables');

      expect(find.text('6 products'), findsOneWidget);
      expect(find.byKey(const ValueKey('product-carrots')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-bananas')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('availableProductsOnly')));
      await tester.pumpAndSettle();
      expect(find.text('5 products'), findsOneWidget);
      expect(find.byKey(const ValueKey('product-cabbage')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('availableProductsOnly')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('product-green-chilli')))
            .dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('product-tomatoes'))).dy,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('toggleProductView')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('productsListView')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('productSearchField')),
        'carrot',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 products'), findsOneWidget);
      expect(find.byKey(const ValueKey('product-carrots')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-cabbage')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('favorite-carrots')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove Carrot from favourites'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('productSearchField')),
        'nothing-matches',
      );
      await tester.pumpAndSettle();
      expect(find.text('No products found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('details quantity updates shared cart; Buy Now opens cart', (
      tester,
    ) async {
      _setPhoneViewport(tester);
      await _openCategory(tester, 'Fruits');
      await tester.tap(find.byKey(const ValueKey('product-bananas')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'banana details layout');

      expect(find.text('Product details'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Related products'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quantity-increase')));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('detailsAddToCart')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'add to cart layout');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('navigation-Cart')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'shared cart layout');
      expect(find.text('Banana'), findsOneWidget);
      expect(find.textContaining('2 dozen'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('navigation-Categories')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-Fruits')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'fruit listing layout');
      await tester.tap(find.byKey(const ValueKey('product-apples')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'apple details layout');
      await tester.tap(find.byKey(const ValueKey('buyNowButton')));
      await tester.pumpAndSettle();
      expect(find.text('My Shopping Cart'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('category listing search and empty state are responsive', (
      tester,
    ) async {
      _setPhoneViewport(tester);
      await _openCategory(tester, 'Vegetables');
      await tester.enterText(
        find.byKey(const ValueKey('productSearchField')),
        'not-in-catalog',
      );
      await tester.pumpAndSettle();
      expect(find.text('No products found'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('productSearchField')),
        'tomato',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('product-tomatoes')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-carrots')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  test('cart uses paise, discounts, stock limits, and delivery rule', () {
    final service = CartService();
    addTearDown(service.dispose);
    final tomato = popularProducts.first;

    service.add(tomato, quantity: 2);
    expect(service.quantityFor(tomato), 2);
    expect(service.listPriceSubtotalPaise, 8000);
    expect(service.subtotalPaise, 8000);
    expect(service.deliveryFeePaise, 3000);
    expect(service.totalPaise, 11000);

    service.setQuantity(tomato, 13);
    expect(service.deliveryFeePaise, 0);
    expect(() => service.setQuantity(tomato, 21), throwsArgumentError);
    service.remove(tomato.productId);
    expect(service.items, isEmpty);
    expect(service.totalPaise, 0);

    const minimumOrderProduct = GroceryProduct(
      name: 'Bulk Rice',
      price: 80,
      unit: 'kg',
      category: 'Rice & Pulses',
      illustration: '🍚',
      backgroundColor: Colors.white,
      accentColor: Colors.green,
      stockCount: 5,
      minimumOrderQuantity: 3,
    );
    expect(
      () => service.add(minimumOrderProduct, quantity: 2),
      throwsStateError,
    );
    service.add(minimumOrderProduct, quantity: 3);
    expect(service.quantityFor(minimumOrderProduct), 3);
    expect(
      () => service.setQuantity(minimumOrderProduct, 2),
      throwsArgumentError,
    );
  });

  test('Indian mobile and PIN validation rejects invalid values', () {
    expect(validateIndianMobile('9876543210'), isNull);
    expect(validateIndianMobile('1234567890'), isNotNull);
    expect(validateIndianMobile('987654321'), isNotNull);
    expect(validateIndianPinCode('560001'), isNull);
    expect(validateIndianPinCode('012345'), isNotNull);
    expect(validateIndianPinCode('56001'), isNotNull);
  });

  testWidgets('address, coupon, UPI checkout and honest payment failure flow', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(const FreshKartApp());
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacementNamed('/home');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const ValueKey('add-Tomatoes')));
    await tester.tap(find.byKey(const ValueKey('add-Tomatoes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('navigation-Cart')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byKey(const ValueKey('quantity-increase')));
      await tester.pump();
    }
    expect(find.text('6 items'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('proceedToCheckout')));
    await tester.pumpAndSettle();
    expect(find.text('Where should we deliver?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('addNewAddress')));
    await tester.pumpAndSettle();

    Future<void> enterAddressField(String key, String value) async {
      final finder = find.byKey(ValueKey('address-$key'));
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
    }

    await enterAddressField('name', 'Asha Rao');
    await enterAddressField('mobile', '9876543210');
    await enterAddressField('house', '12A');
    await enterAddressField('street', 'Green Park Road');
    await enterAddressField('locality', 'Indiranagar');
    await enterAddressField('city', 'Bengaluru');
    await enterAddressField('state', 'Karnataka');
    await enterAddressField('pin', '560001');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('saveAddress')));
    await tester.tap(find.byKey(const ValueKey('saveAddress')));
    await tester.pumpAndSettle();
    expect(find.text('Asha Rao'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('continueWithAddress')),
    );
    await tester.tap(find.byKey(const ValueKey('continueWithAddress')));
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(
      find.textContaining('sample order is not sent or charged'),
      findsOneWidget,
    );
    expect(find.textContaining('Cash'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('couponField')),
      'FRESH10',
    );
    await tester.tap(find.byKey(const ValueKey('applyCoupon')));
    await tester.pumpAndSettle();
    expect(find.text('FRESH10 applied — 10% off, up to ₹100.'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('₹246'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('payment-method-Google Pay')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('placeOrder')));
    await tester.tap(find.byKey(const ValueKey('placeOrder')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Review your order'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirmPlaceOrder')));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Order created'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Google Pay'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const ValueKey('retryPayment')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Payment could not be started'), findsOneWidget);
    expect(find.text('Failed to start'), findsOneWidget);
    expect(find.textContaining('No payment was made'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
