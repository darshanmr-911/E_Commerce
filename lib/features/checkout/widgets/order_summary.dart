import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../services/cart_service.dart';
import '../../../utils/currency.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({
    required this.cartService,
    required this.couponDiscountPaise,
    super.key,
  });

  final CartService cartService;
  final int couponDiscountPaise;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartService,
      builder: (context, child) {
        final total =
            cartService.subtotalPaise +
            cartService.deliveryFeePaise -
            couponDiscountPaise;
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE9EEE7)),
          ),
          child: Column(
            children: [
              _row(
                'Items subtotal',
                formatCurrencyPaise(cartService.listPriceSubtotalPaise),
              ),
              const SizedBox(height: 9),
              _row(
                'Product savings',
                '-${formatCurrencyPaise(cartService.discountPaise)}',
                color: FreshKartColors.green,
              ),
              const SizedBox(height: 9),
              _row(
                'Delivery fee',
                cartService.deliveryFeePaise == 0
                    ? 'FREE'
                    : formatCurrencyPaise(cartService.deliveryFeePaise),
              ),
              if (couponDiscountPaise > 0) ...[
                const SizedBox(height: 9),
                _row(
                  'Coupon savings',
                  '-${formatCurrencyPaise(couponDiscountPaise)}',
                  color: FreshKartColors.green,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(height: 1),
              ),
              _row('Payable amount', formatCurrencyPaise(total), bold: true),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? FreshKartColors.text : FreshKartColors.mutedText,
              fontSize: bold ? 15 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? FreshKartColors.text,
            fontSize: bold ? 16 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
