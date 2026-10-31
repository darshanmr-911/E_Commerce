import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/address.dart';
import '../../../models/order.dart';
import '../../../services/cart_service.dart';
import '../../../services/customer_api_client.dart';
import '../../../utils/currency.dart';
import '../../products/widgets/product_image.dart';
import '../widgets/order_summary.dart';
import '../widgets/payment_method_selector.dart';
import '../../customer/screens/customer_login_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.cartService,
    required this.address,
    required this.onEditAddress,
    this.customerApi,
    this.useBackend = false,
    super.key,
  });

  final CartService cartService;
  final DeliveryAddress address;
  final Future<DeliveryAddress?> Function() onEditAddress;
  final CustomerApiClient? customerApi;
  final bool useBackend;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _couponController = TextEditingController();
  late DeliveryAddress _address;
  String _paymentMethod = 'UPI';
  String? _couponMessage;
  int _couponDiscountPaise = 0;
  bool _couponApplied = false;
  bool _isPlacingOrder = false;
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    _address = widget.address;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  int get _payablePaise => widget.cartService.totalPaise - _couponDiscountPaise;

  Future<void> _editAddress() async {
    final address = await widget.onEditAddress();
    if (address != null && mounted) setState(() => _address = address);
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code != 'FRESH10') {
      setState(() {
        _couponApplied = false;
        _couponDiscountPaise = 0;
        _couponMessage = 'That coupon code is not valid.';
      });
      return;
    }
    if (widget.cartService.subtotalPaise < 20000) {
      setState(() {
        _couponApplied = false;
        _couponDiscountPaise = 0;
        _couponMessage = 'FRESH10 applies to orders of ₹200 or more.';
      });
      return;
    }
    setState(() {
      _couponApplied = true;
      _couponDiscountPaise = (widget.cartService.subtotalPaise ~/ 10).clamp(
        0,
        10000,
      );
      _couponMessage = 'FRESH10 applied — 10% off, up to ₹100.';
    });
  }

  Future<void> _placeOrder() async {
    if (widget.cartService.items.isEmpty) return;
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review your order'),
        content: Text(
          'Your total is ${formatCurrencyPaise(_payablePaise)}. '
          'Payment will remain pending until an UPI gateway is connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review'),
          ),
          FilledButton(
            key: const ValueKey('confirmPlaceOrder'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    if (confirmed != true) return;

    final order = widget.useBackend
        ? await _createServerOrder()
        : GroceryOrder(
            id: 'FK${DateTime.now().microsecondsSinceEpoch}',
            address: _address,
            items: List.of(widget.cartService.items),
            subtotalPaise: widget.cartService.listPriceSubtotalPaise,
            deliveryFeePaise: widget.cartService.deliveryFeePaise,
            discountPaise:
                widget.cartService.discountPaise + _couponDiscountPaise,
            totalPaise: _payablePaise,
            paymentMethod: _paymentMethod,
            paymentStatus: PaymentStatus.pending,
          );
    if (order == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderConfirmationScreen(order: order),
      ),
    );
  }

  Future<GroceryOrder?> _createServerOrder() async {
    final api = widget.customerApi ?? CustomerApiClient();
    final hasSession = await api.hasSession;
    if (!mounted) return null;
    if (!hasSession) {
      final authenticated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CustomerLoginScreen(api: api)),
      );
      if (authenticated != true || !mounted) return null;
    }
    setState(() {
      _isPlacingOrder = true;
      _checkoutError = null;
    });
    try {
      final items = widget.cartService.items.map((item) {
        final productId = int.tryParse(item.product.productId);
        if (productId == null) {
          throw const CustomerApiException(
            'This cart contains a sample product. Refresh the catalog before checkout.',
          );
        }
        return <String, Object?>{
          'product_id': productId,
          'quantity': item.quantity,
        };
      }).toList();
      final result = await api.createOrder(
        address: {
          'name': _address.fullName,
          'mobile': _address.mobileNumber,
          'house_number': _address.houseNumber,
          'street': _address.street,
          'area': _address.locality,
          'city': _address.city,
          'state': _address.state,
          'pin_code': _address.pinCode,
          'label': _address.label,
          'instructions': _address.instructions,
        },
        items: items,
        couponCode: _couponApplied ? _couponController.text.trim() : '',
      );
      final order = GroceryOrder(
        id: 'FK${result['id']}',
        address: _address,
        items: List.of(widget.cartService.items),
        subtotalPaise: _readPaise(result['subtotal']),
        deliveryFeePaise: _readPaise(result['delivery_fee']),
        discountPaise: _readPaise(result['discount']),
        totalPaise: _readPaise(result['total']),
        paymentMethod: _paymentMethod,
        paymentStatus: PaymentStatus.pending,
        isServerBacked: true,
      );
      widget.cartService.clear();
      return order;
    } on CustomerApiException catch (error) {
      if (mounted) setState(() => _checkoutError = error.message);
      return null;
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  int _readPaise(Object? amount) {
    final value = double.tryParse('$amount');
    if (value == null || !value.isFinite) {
      throw const CustomerApiException(
        'The API returned an invalid order total.',
      );
    }
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cartService,
      builder: (context, child) {
        final items = widget.cartService.items;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: FreshKartColors.cream,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Checkout',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: items.isEmpty
              ? const _CheckoutEmptyCart()
              : SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    children: [
                      const _SectionHeading(
                        number: '1',
                        title: 'Delivery address',
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9EEE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _address.fullName,
                                    style: const TextStyle(
                                      color: FreshKartColors.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  key: const ValueKey('editCheckoutAddress'),
                                  onPressed: _editAddress,
                                  child: const Text('Edit'),
                                ),
                              ],
                            ),
                            Text(
                              _address.formattedAddress,
                              style: const TextStyle(
                                color: FreshKartColors.mutedText,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+91 ${_address.mobileNumber}',
                              style: const TextStyle(
                                color: FreshKartColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeading(
                        number: '2',
                        title: 'Order items (${widget.cartService.itemCount})',
                      ),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ProductImage(
                                    product: item.product,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${item.product.name} × ${item.quantity}',
                                  style: const TextStyle(
                                    color: FreshKartColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                formatCurrencyPaise(item.totalPaise),
                                style: const TextStyle(
                                  color: FreshKartColors.darkGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _SectionHeading(number: '3', title: 'Coupon'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('couponField'),
                              controller: _couponController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(13),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE9EEE7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: const ValueKey('applyCoupon'),
                            onPressed: _applyCoupon,
                            child: Text(_couponApplied ? 'Applied' : 'Apply'),
                          ),
                        ],
                      ),
                      if (_couponMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _couponMessage!,
                          key: const ValueKey('couponMessage'),
                          style: TextStyle(
                            color: _couponApplied
                                ? FreshKartColors.green
                                : Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const _SectionHeading(
                        number: '4',
                        title: 'Payment method',
                      ),
                      PaymentMethodSelector(
                        selectedMethod: _paymentMethod,
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3DF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          widget.useBackend
                              ? 'Your order will be saved by FreshKart. UPI is recorded as pending; this app does not collect or verify payment.'
                              : 'Backend is offline. This sample order is not sent or charged; payment stays pending.',
                          style: TextStyle(
                            color: Color(0xFF765322),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      OrderSummary(
                        cartService: widget.cartService,
                        couponDiscountPaise: _couponDiscountPaise,
                      ),
                      if (_checkoutError case final error?) ...[
                        const SizedBox(height: 8),
                        Text(
                          error,
                          key: const ValueKey('checkoutError'),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 17),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          key: const ValueKey('placeOrder'),
                          onPressed: _isPlacingOrder ? null : _placeOrder,
                          style: FilledButton.styleFrom(
                            backgroundColor: FreshKartColors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: _isPlacingOrder
                                ? const SizedBox(
                                    key: ValueKey('placingOrder'),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Place Order · ${formatCurrencyPaise(_payablePaise)}',
                                    key: const ValueKey('placeOrderText'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: const BoxDecoration(
              color: FreshKartColors.paleGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: FreshKartColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: FreshKartColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutEmptyCart extends StatelessWidget {
  const _CheckoutEmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Your cart is empty. Add products before checkout.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FreshKartColors.mutedText, fontSize: 15),
        ),
      ),
    );
  }
}
