import 'package:flutter/material.dart';

import '../../../models/product.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    required this.quantityFor,
    required this.isFavorite,
    required this.onProductTap,
    required this.onAdd,
    required this.onFavoriteTap,
    required this.isList,
    super.key,
  });

  final List<GroceryProduct> products;
  final int Function(GroceryProduct) quantityFor;
  final bool Function(GroceryProduct) isFavorite;
  final ValueChanged<GroceryProduct> onProductTap;
  final ValueChanged<GroceryProduct> onAdd;
  final ValueChanged<GroceryProduct> onFavoriteTap;
  final bool isList;

  @override
  Widget build(BuildContext context) {
    if (isList) {
      return ListView.separated(
        key: const ValueKey('productsListView'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            height: 128,
            child: ProductCard(
              product: product,
              quantity: quantityFor(product),
              isFavorite: isFavorite(product),
              isList: true,
              onTap: () => onProductTap(product),
              onAdd: () => onAdd(product),
              onFavoriteTap: () => onFavoriteTap(product),
            ),
          );
        },
      );
    }

    return GridView.builder(
      key: const ValueKey('productsGridView'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
        mainAxisExtent: 246,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          quantity: quantityFor(product),
          isFavorite: isFavorite(product),
          onTap: () => onProductTap(product),
          onAdd: () => onAdd(product),
          onFavoriteTap: () => onFavoriteTap(product),
        );
      },
    );
  }
}
