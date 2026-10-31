import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/product.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.quantity,
    required this.isFavorite,
    required this.onTap,
    required this.onAdd,
    required this.onFavoriteTap,
    this.isList = false,
    super.key,
  });

  final GroceryProduct product;
  final int quantity;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onFavoriteTap;
  final bool isList;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _favoriteButton() => IconButton(
    key: ValueKey('favorite-${widget.product.productId}'),
    tooltip: widget.isFavorite
        ? 'Remove ${widget.product.name} from favourites'
        : 'Add ${widget.product.name} to favourites',
    onPressed: widget.onFavoriteTap,
    icon: AnimatedScale(
      scale: widget.isFavorite ? 1.15 : 1,
      duration: const Duration(milliseconds: 150),
      child: Icon(
        widget.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: widget.isFavorite
            ? const Color(0xFFD95D58)
            : FreshKartColors.mutedText,
      ),
    ),
  );

  Widget _addButton() => SizedBox(
    height: 36,
    child: OutlinedButton(
      key: ValueKey('add-${widget.product.productId}'),
      onPressed: widget.product.isAvailable && widget.product.stockCount > 0
          ? widget.onAdd
          : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: FreshKartColors.green,
        side: const BorderSide(color: FreshKartColors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      child: Text(
        !widget.product.isAvailable
            ? 'Unavailable'
            : widget.quantity == 0
            ? 'Add to Cart'
            : 'Added (${widget.quantity})',
        maxLines: 1,
      ),
    ),
  );

  Widget _productInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: FreshKartColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Row(
        children: [
          Expanded(
            child: Text(
              widget.product.discountPercent > 0
                  ? widget.product.discountedPriceLabel
                  : widget.product.priceLabel,
              style: const TextStyle(
                color: FreshKartColors.darkGreen,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (widget.product.discountPercent > 0)
            Text(
              '${widget.product.discountPercent}% OFF',
              style: const TextStyle(
                color: Color(0xFFD66C42),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      _addButton(),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
          child: Container(
            key: ValueKey('product-${widget.product.productId}'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEBEFE9)),
              boxShadow: [
                BoxShadow(
                  color: FreshKartColors.darkGreen.withValues(alpha: 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.isList
                ? Row(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 104,
                        child: Hero(
                          tag: 'product-image-${widget.product.productId}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ProductImage(
                              product: widget.product,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: _productInfo()),
                      _favoriteButton(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Hero(
                                tag:
                                    'product-image-${widget.product.productId}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: ProductImage(
                                    product: widget.product,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.product.discountPercent > 0)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FreshKartColors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.product.discountPercent}% OFF',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.94),
                                shape: const CircleBorder(),
                                child: _favoriteButton(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      _productInfo(),
                    ],
                  ),
          ),
        ),
      ),
    );
    return card;
  }
}
