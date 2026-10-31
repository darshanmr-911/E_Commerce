import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/cart_item.dart';
import '../../../utils/currency.dart';
import '../../products/widgets/product_image.dart';
import '../../products/widgets/quantity_selector.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE9EEE7)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 82,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductImage(product: product, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FreshKartColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.priceLabel} · ${item.quantity} ${product.unit}',
                  style: const TextStyle(
                    color: FreshKartColors.mutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                QuantitySelector(
                  quantity: item.quantity,
                  maximum: product.stockCount,
                  minimum: product.minimumOrderQuantity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                key: ValueKey('remove-cart-${product.productId}'),
                tooltip: 'Remove ${product.name}',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: FreshKartColors.mutedText,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                formatCurrencyPaise(item.totalPaise),
                style: const TextStyle(
                  color: FreshKartColors.darkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
