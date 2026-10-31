import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';

const _orderStatuses = [
  '',
  'new',
  'accepted',
  'preparing',
  'ready',
  'out_for_delivery',
  'delivered',
  'rejected',
  'cancelled',
];

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({required this.api, super.key});

  final OwnerApiClient api;

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  String _status = '';
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _orders = widget.api.getList(
        '/owner/orders/${_status.isEmpty ? '' : '?status=$_status'}',
      );
    });
  }

  Future<void> _changeStatus(Map<String, dynamic> order, String target) async {
    String reason = '';
    if (target == 'rejected') {
      final controller = TextEditingController();
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject order'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 240,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Reject order'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (value == null) return;
      reason = value;
    }
    try {
      await widget.api.patch('/owner/orders/${order['id']}/status/', {
        'status': target,
        if (reason.isNotEmpty) 'reason': reason,
      });
      _reload();
    } on OwnerApiException catch (error) {
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
        'Orders',
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
    body: Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            scrollDirection: Axis.horizontal,
            children: _orderStatuses.map((status) {
              final selected = status == _status;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(status.isEmpty ? 'All' : _statusLabel(status)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _status = status);
                    _reload();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _orders,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _OrderError(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('No orders in this view.'));
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _OrderCard(
                    order: snapshot.data![index],
                    onStatus: (target) =>
                        _changeStatus(snapshot.data![index], target),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onStatus});

  final Map<String, dynamic> order;
  final ValueChanged<String> onStatus;

  List<String> get _actions {
    switch (order['status']) {
      case 'new':
        return ['accepted', 'rejected'];
      case 'accepted':
        return ['preparing', 'cancelled'];
      case 'preparing':
        return ['ready', 'cancelled'];
      case 'ready':
        return ['out_for_delivery', 'cancelled'];
      case 'out_for_delivery':
        return ['delivered'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = order['delivery_address_snapshot'];
    final addressText = address is Map<String, dynamic>
        ? [
            address['name'],
            address['line1'] ?? address['house_number'],
            address['area'],
            address['city'],
            address['pin_code'],
          ].where((part) => part != null && '$part'.isNotEmpty).join(', ')
        : 'Customer delivery address';
    final items = order['items'] is List
        ? (order['items'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    return Container(
      padding: const EdgeInsets.all(16),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _StatusBadge(status: '${order['status']}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            addressText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FreshKartColors.mutedText,
              fontSize: 12,
            ),
          ),
          const Divider(height: 20),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['product_name_snapshot']} × ${item['quantity']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('₹${item['line_total']}'),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment: ${_statusLabel('${order['payment_status']}')}',
                  style: const TextStyle(
                    color: FreshKartColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '₹${order['total']}',
                style: const TextStyle(
                  color: FreshKartColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          if (_actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _actions.map((action) {
                final destructive =
                    action == 'rejected' || action == 'cancelled';
                return OutlinedButton(
                  onPressed: () => onStatus(action),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: destructive
                        ? Colors.redAccent
                        : FreshKartColors.green,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_actionLabel(action)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: status == 'new'
          ? const Color(0xFFFFF1DE)
          : FreshKartColors.paleGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          color: FreshKartColors.darkGreen,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'new' => 'New',
  'accepted' => 'Accepted',
  'preparing' => 'Preparing',
  'ready' => 'Ready for dispatch',
  'out_for_delivery' => 'Out for delivery',
  'delivered' => 'Delivered',
  'rejected' => 'Rejected',
  'cancelled' => 'Cancelled',
  'pending' => 'Pending',
  'paid' => 'Paid',
  'failed' => 'Failed',
  _ => status,
};

String _actionLabel(String action) => switch (action) {
  'accepted' => 'Accept',
  'rejected' => 'Reject',
  'preparing' => 'Start preparing',
  'ready' => 'Ready for dispatch',
  'out_for_delivery' => 'Out for delivery',
  'delivered' => 'Mark delivered',
  'cancelled' => 'Cancel',
  _ => action,
};

class _OrderError extends StatelessWidget {
  const _OrderError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
