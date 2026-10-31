import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/order.dart';
import '../../../utils/currency.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({required this.order, super.key});

  final GroceryOrder order;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late GroceryOrder _order;
  late final AnimationController _entrance;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _retryPayment() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _isRetrying = false;
      _order = _order.copyWith(paymentStatus: PaymentStatus.failed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = _order.paymentStatus == PaymentStatus.failed;
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FreshKartColors.cream,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text('Order status'),
      ),
      body: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(animation),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 38, 22, 30),
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: isFailed
                      ? const Color(0xFFFFE9E7)
                      : FreshKartColors.paleGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFailed
                      ? Icons.error_outline_rounded
                      : Icons.receipt_long_rounded,
                  color: isFailed ? Colors.redAccent : FreshKartColors.green,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isFailed ? 'Payment could not be started' : 'Order created',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FreshKartColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFailed
                    ? 'The UPI gateway is not connected. No payment was made or amount charged.'
                    : widget.order.isServerBacked
                    ? 'Your order is saved on FreshKart. Payment remains pending; this app has not charged you.'
                    : 'Your local sample order is saved. Payment is pending; this app has not charged you.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEE7)),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Order ID', value: _order.id),
                    const SizedBox(height: 11),
                    _InfoRow(
                      label: 'Payment status',
                      value: isFailed ? 'Failed to start' : 'Pending',
                      valueColor: isFailed
                          ? Colors.redAccent
                          : FreshKartColors.green,
                    ),
                    const SizedBox(height: 11),
                    _InfoRow(
                      label: 'Amount',
                      value: formatCurrencyPaise(_order.totalPaise),
                    ),
                    const SizedBox(height: 11),
                    _InfoRow(
                      label: 'Payment method',
                      value: _order.paymentMethod,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Text(
                  'This is a frontend demonstration only. Payment must be completed through a supported UPI gateway before an order can be fulfilled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF765322),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                key: const ValueKey('retryPayment'),
                onPressed: _isRetrying ? null : _retryPayment,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FreshKartColors.green,
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: FreshKartColors.green),
                ),
                child: _isRetrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isFailed
                            ? 'Try UPI payment again'
                            : 'Retry UPI payment',
                      ),
              ),
              const SizedBox(height: 9),
              TextButton(
                key: const ValueKey('continueAfterOrder'),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = FreshKartColors.text,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: FreshKartColors.mutedText,
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
