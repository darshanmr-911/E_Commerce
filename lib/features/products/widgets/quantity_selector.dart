import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    required this.quantity,
    required this.maximum,
    required this.onChanged,
    this.minimum = 1,
    super.key,
  });

  final int quantity;
  final int maximum;
  final ValueChanged<int> onChanged;
  final int minimum;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FreshKartColors.paleGreen,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('quantity-decrease'),
            onPressed: quantity > minimum
                ? () => onChanged(quantity - 1)
                : null,
            icon: const Icon(Icons.remove_rounded),
            color: FreshKartColors.green,
            visualDensity: VisualDensity.compact,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: const TextStyle(
                color: FreshKartColors.darkGreen,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('quantity-increase'),
            onPressed: quantity < maximum
                ? () => onChanged(quantity + 1)
                : null,
            icon: const Icon(Icons.add_rounded),
            color: FreshKartColors.green,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
