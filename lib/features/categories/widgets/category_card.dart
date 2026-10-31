import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/category.dart';

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    required this.category,
    required this.index,
    required this.onTap,
    super.key,
  });

  final GroceryCategory category;
  final int index;
  final VoidCallback onTap;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entrance;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    Future<void>.delayed(Duration(milliseconds: widget.index * 45), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _imageFallback() {
    return ColoredBox(
      color: widget.category.backgroundColor,
      child: Center(
        child: Text(
          widget.category.illustration,
          style: const TextStyle(fontSize: 34),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.07),
          end: Offset.zero,
        ).animate(_entrance),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Container(
              key: ValueKey('category-${widget.category.name}'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBEFE9)),
                boxShadow: [
                  BoxShadow(
                    color: FreshKartColors.darkGreen.withValues(alpha: 0.055),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.category.imageUrl.isEmpty
                          ? _imageFallback()
                          : Image.network(
                              widget.category.imageUrl,
                              fit: BoxFit.cover,
                              semanticLabel: widget.category.name,
                              loadingBuilder:
                                  (context, child, loadingProgress) =>
                                      loadingProgress == null
                                      ? child
                                      : _imageFallback(),
                              errorBuilder: (context, error, stackTrace) =>
                                  _imageFallback(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FreshKartColors.text,
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.category.description,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FreshKartColors.mutedText,
                      fontSize: 9,
                      height: 1.2,
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
