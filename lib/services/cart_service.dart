import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  Map<String, int> get quantities => Map.unmodifiable({
    for (final entry in _items.entries) entry.key: entry.value.quantity,
  });

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  int get subtotalPaise =>
      _items.values.fold(0, (total, item) => total + item.totalPaise);

  int get listPriceSubtotalPaise => _items.values.fold(
    0,
    (total, item) => total + item.product.pricePaise * item.quantity,
  );

  int get discountPaise => listPriceSubtotalPaise - subtotalPaise;

  int get deliveryFeePaise =>
      subtotalPaise == 0 || subtotalPaise >= 50000 ? 0 : 3000;

  int get totalPaise => subtotalPaise + deliveryFeePaise;

  int quantityFor(GroceryProduct product) =>
      _items[product.productId]?.quantity ?? 0;

  void add(GroceryProduct product, {int quantity = 1}) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive.');
    }
    if (!product.isAvailable || product.stockCount <= 0) {
      throw StateError('${product.name} is unavailable.');
    }
    final current = quantityFor(product);
    if (current + quantity < product.minimumOrderQuantity) {
      throw StateError(
        'The minimum order for ${product.name} is ${product.minimumOrderQuantity}.',
      );
    }
    if (current + quantity > product.stockCount) {
      throw StateError('Only ${product.stockCount} ${product.name} available.');
    }
    _items[product.productId] = CartItem(
      product: product,
      quantity: current + quantity,
    );
    notifyListeners();
  }

  void setQuantity(GroceryProduct product, int quantity) {
    if (quantity < 0 ||
        quantity > product.stockCount ||
        (quantity > 0 && quantity < product.minimumOrderQuantity)) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Must be between zero and available stock.',
      );
    }
    if (quantity == 0) {
      remove(product.productId);
      return;
    }
    _items[product.productId] = CartItem(product: product, quantity: quantity);
    notifyListeners();
  }

  void remove(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }

  void clear() {
    if (_items.isNotEmpty) {
      _items.clear();
      notifyListeners();
    }
  }
}
