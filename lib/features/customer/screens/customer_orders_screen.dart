import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../services/customer_api_client.dart';
import 'customer_login_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({required this.api, super.key});

  final CustomerApiClient api;

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    if (!await widget.api.hasSession) {
      throw const CustomerApiException('Sign in to view your orders.');
    }
    return widget.api.fetchOrders();
  }

  void _reload() => setState(() => _orders = _loadOrders());

  Future<void> _signIn() async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerLoginScreen(api: widget.api)),
    );
    if (success == true) _reload();
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'Stock will be returned to the shop. Cancellation is only available before delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.cancelOrder(order['id'] as int);
      _reload();
    } on CustomerApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Your orders',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: FreshKartColors.cream,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: 'Refresh orders',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final requiresSignIn =
              snapshot.error is CustomerApiException &&
              '${snapshot.error}'.contains('Sign in');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    requiresSignIn
                        ? Icons.person_outline_rounded
                        : Icons.cloud_off_rounded,
                    color: FreshKartColors.green,
                    size: 38,
                  ),
                  const SizedBox(height: 10),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: requiresSignIn ? _signIn : _reload,
                    child: Text(requiresSignIn ? 'Customer sign in' : 'Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(
            child: Text('Your FreshKart orders will appear here.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CustomerOrderCard(
              order: orders[index],
              onCancel: () => _cancelOrder(orders[index]),
            ),
          ),
        );
      },
    ),
  );
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order, required this.onCancel});

  final Map<String, dynamic> order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final items = order['items'] is List
        ? (order['items'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final address = order['delivery_address_snapshot'];
    final city = address is Map<String, dynamic>
        ? '${address['city'] ?? ''}'
        : '';
    final status = '${order['status'] ?? 'new'}';
    final paymentStatus = '${order['payment_status'] ?? 'pending'}';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9EEE7)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    color: FreshKartColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _label(status),
                style: const TextStyle(
                  color: FreshKartColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (city.isNotEmpty)
            Text(
              'Delivery to $city',
              style: const TextStyle(
                color: FreshKartColors.mutedText,
                fontSize: 12,
              ),
            ),
          const Divider(height: 19),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '${item['product_name_snapshot']} × ${item['quantity']}  ·  ₹${item['line_total']}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment ${_label(paymentStatus)}',
                  style: const TextStyle(
                    color: FreshKartColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '₹${order['total']}',
                style: const TextStyle(
                  color: FreshKartColors.darkGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (['new', 'accepted', 'preparing'].contains(status)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel order'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _label(String value) => value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
