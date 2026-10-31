import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod,
    required this.onChanged,
    super.key,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  static const _methods = [
    ('UPI', 'Pay with any supported UPI app', Icons.account_balance_wallet),
    ('Google Pay', 'Continue with Google Pay via UPI', Icons.g_mobiledata),
    ('PhonePe', 'Continue with PhonePe via UPI', Icons.phone_android),
    ('Other UPI app', 'Choose another supported UPI app', Icons.apps_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _methods.map((method) {
        final selected = selectedMethod == method.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            key: ValueKey('payment-method-${method.$1}'),
            onTap: () => onChanged(method.$1),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? FreshKartColors.paleGreen : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? FreshKartColors.green
                      : const Color(0xFFE9EEE7),
                ),
              ),
              child: Row(
                children: [
                  Icon(method.$3, color: FreshKartColors.green),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.$1,
                          style: const TextStyle(
                            color: FreshKartColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method.$2,
                          style: const TextStyle(
                            color: FreshKartColors.mutedText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? FreshKartColors.green
                        : FreshKartColors.mutedText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
