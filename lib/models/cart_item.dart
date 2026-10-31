import 'product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final GroceryProduct product;
  final int quantity;

  int get totalPaise => product.discountedPricePaise * quantity;
}
