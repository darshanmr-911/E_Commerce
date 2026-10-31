import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';
import 'owner_inventory_screen.dart';
import 'owner_orders_screen.dart';
import 'owner_products_screen.dart';
import 'owner_profile_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    required this.api,
    required this.onLogout,
    super.key,
  });

  final OwnerApiClient api;
  final VoidCallback onLogout;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _destination = 0;
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = widget.api.getObject('/owner/dashboard/');
  }

  void _refresh() {
    setState(() => _dashboard = widget.api.getObject('/owner/dashboard/'));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildDashboard(),
      OwnerProductsScreen(api: widget.api),
      OwnerInventoryScreen(api: widget.api),
      OwnerOrdersScreen(api: widget.api),
      OwnerProfileScreen(api: widget.api, onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _destination, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _destination,
        onDestinationSelected: (index) => setState(() => _destination = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            selectedIcon: Icon(Icons.warehouse_rounded),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboard,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Owner dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: FreshKartColors.text,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'A fresh look at your shop today.',
                          style: TextStyle(color: FreshKartColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh dashboard',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                _ApiErrorCard(
                  message: snapshot.error.toString(),
                  onRetry: _refresh,
                )
              else if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data != null) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 640 ? 4 : 2;
                    final cardWidth =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    final stats = [
                      _Stat(
                        'Products',
                        _number(data, 'total_products'),
                        Icons.inventory_2_rounded,
                        const Color(0xFFE7F3E9),
                      ),
                      _Stat(
                        'Available',
                        _number(data, 'available_products'),
                        Icons.check_circle_outline_rounded,
                        const Color(0xFFE8F4EB),
                      ),
                      _Stat(
                        'Unavailable',
                        _number(data, 'unavailable_products'),
                        Icons.pause_circle_outline_rounded,
                        const Color(0xFFFFF1DE),
                      ),
                      _Stat(
                        'Low stock',
                        _number(data, 'low_stock_products'),
                        Icons.warning_amber_rounded,
                        const Color(0xFFFFE9E5),
                      ),
                      _Stat(
                        'Orders',
                        _number(data, 'total_orders'),
                        Icons.receipt_long_rounded,
                        const Color(0xFFEAF0FF),
                      ),
                      _Stat(
                        'Pending',
                        _number(data, 'pending_orders'),
                        Icons.hourglass_bottom_rounded,
                        const Color(0xFFFFF1DE),
                      ),
                      _Stat(
                        'Completed',
                        _number(data, 'completed_orders'),
                        Icons.task_alt_rounded,
                        const Color(0xFFE8F4EB),
                      ),
                      _Stat(
                        "Today's sales",
                        '₹${data['today_sales'] ?? '0.00'}',
                        Icons.currency_rupee_rounded,
                        const Color(0xFFEAF0FF),
                      ),
                    ];
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: stats
                          .map(
                            (stat) => SizedBox(
                              width: cardWidth,
                              child: _StatCard(stat: stat),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent orders',
                        style: TextStyle(
                          color: FreshKartColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _destination = 3),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._recentOrders(data['recent_orders']),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _recentOrders(Object? value) {
    if (value is! List || value.isEmpty) {
      return const [
        _OwnerCard(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'No orders have arrived yet.',
              style: TextStyle(color: FreshKartColors.mutedText),
            ),
          ),
        ),
      ];
    }
    return value.whereType<Map<String, dynamic>>().map((order) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _OwnerCard(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: FreshKartColors.paleGreen,
              child: Icon(Icons.receipt_long, color: FreshKartColors.green),
            ),
            title: Text('Order #${order['id']}'),
            subtitle: Text('${order['order_status'] ?? 'new'}'),
            trailing: Text('₹${order['total'] ?? '0.00'}'),
          ),
        ),
      );
    }).toList();
  }

  static String _number(Map<String, dynamic> data, String key) =>
      '${data[key] ?? 0}';
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return _OwnerCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: stat.color,
              child: Icon(stat.icon, size: 20, color: FreshKartColors.green),
            ),
            const SizedBox(height: 13),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat.value,
                style: const TextStyle(
                  color: FreshKartColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FreshKartColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiErrorCard extends StatelessWidget {
  const _ApiErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _OwnerCard(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.redAccent,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE9EEE7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080D2918),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}
