import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/product.dart';
import 'product_card.dart';

class ProductSection extends StatelessWidget {
  const ProductSection({
    required this.products,
    required this.cartQuantities,
    required this.favorites,
    required this.onAdd,
    required this.onRemove,
    required this.onFavoriteTap,
    this.title = 'Popular products',
    super.key,
  });

  final List<GroceryProduct> products;
  final Map<String, int> cartQuantities;
  final Set<String> favorites;
  final ValueChanged<GroceryProduct> onAdd;
  final ValueChanged<GroceryProduct> onRemove;
  final ValueChanged<GroceryProduct> onFavoriteTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FreshKartColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 13),
          if (products.isEmpty)
            const _EmptyProducts()
          else
            GridView.builder(
              key: const ValueKey('productGrid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 208,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  quantity: cartQuantities[product.name] ?? 0,
                  isFavorite: favorites.contains(product.productId),
                  onAdd: () => onAdd(product),
                  onRemove: () => onRemove(product),
                  onFavoriteTap: () => onFavoriteTap(product),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: FreshKartColors.mutedText,
          ),
          SizedBox(height: 9),
          Text(
            'No sample products here yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FreshKartColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'More fresh picks are coming soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FreshKartColors.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
