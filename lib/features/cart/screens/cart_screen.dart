import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../services/cart_service.dart';
import '../widgets/cart_summary.dart';
import '../widgets/cart_item_card.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    required this.cartService,
    required this.onContinueShopping,
    required this.onProceedToCheckout,
    super.key,
  });

  final CartService cartService;
  final VoidCallback onContinueShopping;
  final VoidCallback onProceedToCheckout;

  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep items'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (shouldClear == true) cartService.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartService,
      builder: (context, child) {
        if (cartService.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: FreshKartColors.paleGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: FreshKartColors.green,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Your cart is waiting',
                    style: TextStyle(
                      color: FreshKartColors.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Add a few fresh favourites and they’ll be ready for you here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FreshKartColors.mutedText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 17),
                  FilledButton(
                    key: const ValueKey('continueShopping'),
                    onPressed: onContinueShopping,
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 16, 13, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Shopping Cart',
                      style: TextStyle(
                        color: FreshKartColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    '${cartService.itemCount} items',
                    style: const TextStyle(
                      color: FreshKartColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('clearCart'),
                    tooltip: 'Clear cart',
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                itemCount: cartService.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = cartService.items[index];
                  return CartItemCard(
                    key: ValueKey('cart-item-${item.product.productId}'),
                    item: item,
                    onQuantityChanged: (quantity) =>
                        cartService.setQuantity(item.product, quantity),
                    onRemove: () => cartService.remove(item.product.productId),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 15),
              child: Column(
                children: [
                  CartSummary(cartService: cartService),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('continueShopping'),
                          onPressed: onContinueShopping,
                          child: const Text('Continue Shopping'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('proceedToCheckout'),
                          onPressed: onProceedToCheckout,
                          style: FilledButton.styleFrom(
                            backgroundColor: FreshKartColors.green,
                          ),
                          child: const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
