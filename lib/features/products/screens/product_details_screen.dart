import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/product.dart';
import '../../../services/cart_service.dart';
import '../../categories/data/categories_sample_data.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_selector.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    required this.product,
    required this.cartService,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.isProductFavorite,
    required this.onBuyNow,
    super.key,
  });

  final GroceryProduct product;
  final CartService cartService;
  final bool isFavorite;
  final ValueChanged<GroceryProduct> onFavoriteTap;
  final bool Function(GroceryProduct) isProductFavorite;
  final void Function(GroceryProduct, int) onBuyNow;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late int _quantity;
  late bool _isFavorite;

  int get _availableToAdd =>
      widget.product.stockCount -
      widget.cartService.quantityFor(widget.product);

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minimumOrderQuantity;
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite(GroceryProduct product) {
    widget.onFavoriteTap(product);
    if (product.productId == widget.product.productId) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  void _addToCart() {
    try {
      widget.cartService.add(widget.product, quantity: _quantity);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$_quantity ${widget.product.name} added to your cart',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final related = categorySampleProducts
        .where(
          (item) =>
              item.categoryId == product.categoryId &&
              item.productId != product.productId,
        )
        .take(4)
        .toList();
    final available = product.isAvailable && _availableToAdd > 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FreshKartColors.cream,
        surfaceTintColor: Colors.transparent,
        title: const Text('Product details'),
        actions: [
          IconButton(
            key: ValueKey('details-favorite-${product.productId}'),
            tooltip: _isFavorite
                ? 'Remove ${product.name} from favourites'
                : 'Add ${product.name} to favourites',
            onPressed: () => _toggleFavorite(product),
            icon: AnimatedScale(
              scale: _isFavorite ? 1.15 : 1,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite
                    ? const Color(0xFFD95D58)
                    : FreshKartColors.mutedText,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.34,
              child: Hero(
                tag: 'product-image-${product.productId}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: ProductImage(product: product, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.category,
              style: const TextStyle(
                color: FreshKartColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              style: const TextStyle(
                color: FreshKartColors.text,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    product.discountPercent > 0
                        ? product.discountedPriceLabel
                        : product.priceLabel,
                    key: ValueKey(product.discountedPricePaise),
                    style: const TextStyle(
                      color: FreshKartColors.darkGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (product.discountPercent > 0) ...[
                  Text(
                    product.priceLabel,
                    style: const TextStyle(
                      color: FreshKartColors.mutedText,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    '${product.discountPercent}% off',
                    style: const TextStyle(
                      color: Color(0xFFD66C42),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Price per ${product.unit}',
              style: const TextStyle(
                color: FreshKartColors.mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  available
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 18,
                  color: available ? FreshKartColors.green : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  available
                      ? 'In stock · $_availableToAdd available'
                      : 'Out of stock',
                  style: TextStyle(
                    color: available ? FreshKartColors.green : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              product.description.isEmpty
                  ? 'A fresh everyday favourite, selected with care for your home.'
                  : product.description,
              style: const TextStyle(
                color: FreshKartColors.mutedText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Quantity',
                    style: TextStyle(
                      color: FreshKartColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                QuantitySelector(
                  quantity: _quantity,
                  maximum: _availableToAdd.clamp(1, product.stockCount),
                  minimum: product.minimumOrderQuantity,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('detailsAddToCart'),
                    onPressed: available ? _addToCart : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FreshKartColors.green,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: FreshKartColors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('buyNowButton'),
                    onPressed: available
                        ? () => widget.onBuyNow(product, _quantity)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FreshKartColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
            if (related.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text(
                'Related products',
                style: TextStyle(
                  color: FreshKartColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = related[index];
                    return SizedBox(
                      width: 112,
                      child: _RelatedProductCard(
                        product: item,
                        isFavorite: widget.isProductFavorite(item),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ProductDetailsScreen(
                              product: item,
                              cartService: widget.cartService,
                              isFavorite: widget.isProductFavorite(item),
                              onFavoriteTap: _toggleFavorite,
                              isProductFavorite: widget.isProductFavorite,
                              onBuyNow: widget.onBuyNow,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
  });

  final GroceryProduct product;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE9EEE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  child: ProductImage(product: product, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FreshKartColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              product.priceLabel,
              style: const TextStyle(
                color: FreshKartColors.mutedText,
                fontSize: 10,
              ),
            ),
            Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
              size: 11,
              color: isFavorite ? Colors.redAccent : FreshKartColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
