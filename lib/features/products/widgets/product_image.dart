import 'package:flutter/material.dart';

import '../../../models/product.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.product, required this.fit, super.key});

  final GroceryProduct product;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: product.backgroundColor,
      child: Center(
        child: Text(product.illustration, style: const TextStyle(fontSize: 44)),
      ),
    );
    if (product.imageUrl.isEmpty) return fallback;
    return Image.network(
      product.imageUrl,
      fit: fit,
      semanticLabel: product.name,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
