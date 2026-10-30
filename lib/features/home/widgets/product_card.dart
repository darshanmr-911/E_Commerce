import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/product.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.quantity,
    required this.isFavorite,
    required this.onAdd,
    required this.onRemove,
    required this.onFavoriteTap,
    super.key,
  });

  final GroceryProduct product;
  final int quantity;
  final bool isFavorite;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onFavoriteTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entrance;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_entrance),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              key: ValueKey('product-${widget.product.name}'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBEFE9)),
                boxShadow: [
                  BoxShadow(
                    color: FreshKartColors.darkGreen.withValues(alpha: 0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: widget.product.backgroundColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.product.illustration,
                            style: const TextStyle(fontSize: 51),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.94),
                            shape: const CircleBorder(),
                            child: IconButton(
                              key: ValueKey('favorite-${widget.product.name}'),
                              tooltip: widget.isFavorite
                                  ? 'Remove ${widget.product.name} from favourites'
                                  : 'Add ${widget.product.name} to favourites',
                              onPressed: widget.onFavoriteTap,
                              constraints: const BoxConstraints.tightFor(
                                width: 31,
                                height: 31,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                widget.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 17,
                                color: widget.isFavorite
                                    ? const Color(0xFFD95D58)
                                    : FreshKartColors.mutedText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
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
                  Text(
                    widget.product.priceLabel,
                    style: const TextStyle(
                      color: FreshKartColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 35,
                    width: double.infinity,
                    child: widget.quantity == 0
                        ? OutlinedButton.icon(
                            key: ValueKey('add-${widget.product.name}'),
                            onPressed: widget.onAdd,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: FreshKartColors.green,
                              side: const BorderSide(
                                color: FreshKartColors.green,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : _QuantityControl(
                            quantity: widget.quantity,
                            onAdd: widget.onAdd,
                            onRemove: widget.onRemove,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FreshKartColors.paleGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const ValueKey('removeFromCartButton'),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_rounded, size: 17),
            color: FreshKartColors.green,
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: FreshKartColors.darkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            key: const ValueKey('addToCartButton'),
            onPressed: onAdd,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 17),
            color: FreshKartColors.green,
          ),
        ],
      ),
    );
  }
}
