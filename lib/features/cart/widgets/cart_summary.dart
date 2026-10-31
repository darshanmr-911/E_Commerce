import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../services/cart_service.dart';
import '../../../utils/currency.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({required this.cartService, super.key});

  final CartService cartService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartService,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EEE7)),
        ),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: formatCurrencyPaise(cartService.listPriceSubtotalPaise),
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Delivery fee',
              value: cartService.deliveryFeePaise == 0
                  ? 'FREE'
                  : formatCurrencyPaise(cartService.deliveryFeePaise),
            ),
            if (cartService.discountPaise > 0) ...[
              const SizedBox(height: 10),
              _SummaryRow(
                label: 'Product savings',
                value: '-${formatCurrencyPaise(cartService.discountPaise)}',
                valueColor: FreshKartColors.green,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _SummaryRow(
              label: 'Total',
              value: formatCurrencyPaise(cartService.totalPaise),
              prominent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = FreshKartColors.text,
    this.prominent = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: prominent
                  ? FreshKartColors.text
                  : FreshKartColors.mutedText,
              fontSize: prominent ? 15 : 13,
              fontWeight: prominent ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: prominent ? 16 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
