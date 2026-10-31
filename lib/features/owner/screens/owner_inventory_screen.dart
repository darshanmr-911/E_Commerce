import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';

class OwnerInventoryScreen extends StatefulWidget {
  const OwnerInventoryScreen({required this.api, super.key});

  final OwnerApiClient api;

  @override
  State<OwnerInventoryScreen> createState() => _OwnerInventoryScreenState();
}

class _OwnerInventoryScreenState extends State<OwnerInventoryScreen> {
  bool _lowStockOnly = false;
  late Future<List<Map<String, dynamic>>> _inventory;
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _inventory = widget.api.getList(
        '/owner/inventory/${_lowStockOnly ? '?low_stock=true' : ''}',
      );
      _history = widget.api.getList('/owner/stock-history/');
    });
  }

  Future<void> _adjustStock(Map<String, dynamic> item, int direction) async {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    final product = item['product'] as Map<String, dynamic>? ?? {};
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(direction > 0 ? 'Add stock' : 'Reduce stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to ${direction > 0 ? 'add' : 'reduce'}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed == null ||
                  parsed <= 0 ||
                  reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('Save adjustment'),
          ),
        ],
      ),
    );
    if (quantity == null) return;
    try {
      await widget.api.patch('/owner/products/${product['id']}/stock/', {
        'quantity_change': direction * quantity,
        'reason': reasonController.text.trim(),
      });
      _reload();
    } on OwnerApiException catch (error) {
      _showError(error.message);
    } finally {
      controller.dispose();
      reasonController.dispose();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Inventory',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: FreshKartColors.cream,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: 'Refresh inventory',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            value: _lowStockOnly,
            activeTrackColor: FreshKartColors.green,
            title: const Text(
              'Show low-stock products only',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Items at or below their configured threshold',
            ),
            onChanged: (value) {
              setState(() => _lowStockOnly = value);
              _reload();
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _inventory,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorPanel(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No products match this inventory filter.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: rows
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InventoryCard(
                          item: item,
                          onAdd: () => _adjustStock(item, 1),
                          onReduce: () => _adjustStock(item, -1),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Stock movement history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FreshKartColors.text,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorPanel(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Text('Stock movements will appear here.');
              }
              return Column(
                children: snapshot.data!
                    .map((movement) => _MovementRow(movement: movement))
                    .toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.onAdd,
    required this.onReduce,
  });

  final Map<String, dynamic> item;
  final VoidCallback onAdd;
  final VoidCallback onReduce;

  @override
  Widget build(BuildContext context) {
    final product = item['product'] as Map<String, dynamic>? ?? {};
    final stock = item['stock_quantity'] ?? 0;
    final low = item['is_low_stock'] == true;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9EEE7)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: low
                ? const Color(0xFFFFEEE0)
                : FreshKartColors.paleGreen,
            child: Icon(
              low ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
              color: low ? Colors.deepOrange : FreshKartColors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['name'] ?? 'Product'}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Stock $stock · threshold ${item['low_stock_threshold']}',
                  style: TextStyle(
                    color: low ? Colors.deepOrange : FreshKartColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reduce stock',
            onPressed: onReduce,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            tooltip: 'Add stock',
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_circle_outline,
              color: FreshKartColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final Map<String, dynamic> movement;

  @override
  Widget build(BuildContext context) {
    final change = movement['quantity_change'] as int? ?? 0;
    final date = DateTime.tryParse('${movement['created_at'] ?? ''}')
        ?.toLocal();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: change >= 0
            ? FreshKartColors.paleGreen
            : const Color(0xFFFFEEE0),
        child: Icon(
          change >= 0 ? Icons.add_rounded : Icons.remove_rounded,
          color: change >= 0 ? FreshKartColors.green : Colors.deepOrange,
          size: 18,
        ),
      ),
      title: Text(
        '${movement['product_name'] ?? 'Product'} · ${change > 0 ? '+' : ''}$change',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${movement['reason'] ?? ''} · ${movement['updated_by'] ?? 'Owner'}'
        '${date == null ? '' : ' · ${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'}',
        maxLines: 2,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message, textAlign: TextAlign.center),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}
