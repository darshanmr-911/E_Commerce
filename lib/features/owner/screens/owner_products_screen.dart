import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../services/owner_api_client.dart';
import 'owner_product_form_screen.dart';

class OwnerProductsScreen extends StatefulWidget {
  const OwnerProductsScreen({required this.api, super.key});

  final OwnerApiClient api;

  @override
  State<OwnerProductsScreen> createState() => _OwnerProductsScreenState();
}

class _OwnerProductsScreenState extends State<OwnerProductsScreen> {
  final _search = TextEditingController();
  String _availability = '';
  String _category = '';
  List<Map<String, dynamic>> _categories = [];
  late Future<List<Map<String, dynamic>>> _products;

  @override
  void initState() {
    super.initState();
    _products = _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.api.getList('/categories/');
      if (mounted) setState(() => _categories = categories);
    } on OwnerApiException catch (error) {
      _showError(error.message);
    }
  }

  Future<List<Map<String, dynamic>>> _loadProducts() => widget.api.getList(
    '/owner/products/?search=${Uri.encodeQueryComponent(_search.text.trim())}'
    '${_availability.isEmpty ? '' : '&available=$_availability'}'
    '${_category.isEmpty ? '' : '&category=$_category'}',
  );

  void _reload() => setState(() => _products = _loadProducts());

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            OwnerProductFormScreen(api: widget.api, product: product),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _createProduct() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerProductFormScreen(api: widget.api),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _setAvailability(
    Map<String, dynamic> product,
    bool active,
  ) async {
    try {
      await widget.api.patch('/owner/products/${product['id']}/availability/', {
        'is_active': active,
      });
      _reload();
    } on OwnerApiException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _archiveProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive product?'),
        content: Text(
          '${product['name']} will no longer be shown to customers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.delete('/owner/products/${product['id']}/');
      _reload();
    } on OwnerApiException catch (error) {
      _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage products',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: FreshKartColors.cream,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const ValueKey('ownerAddProduct'),
            onPressed: _createProduct,
            tooltip: 'Add product',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            onPressed: _reload,
            tooltip: 'Refresh products',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _reload(),
                  decoration: InputDecoration(
                    hintText: 'Search your products...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: _reload,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const ValueKey('ownerCategoryFilter'),
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All categories'),
                          ),
                          ..._categories.map(
                            (category) => DropdownMenuItem(
                              value: '${category['id']}',
                              child: Text('${category['name']}'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _category = value ?? '');
                          _reload();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const ValueKey('ownerAvailabilityFilter'),
                        initialValue: _availability,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Availability',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All')),
                          DropdownMenuItem(
                            value: 'true',
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: 'false',
                            child: Text('Unavailable'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _availability = value ?? '');
                          _reload();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _products,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ProductsError(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No products found. Add your first product to get started.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 90),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _OwnerProductCard(
                        product: product,
                        onEdit: () => _editProduct(product),
                        onArchive: () => _archiveProduct(product),
                        onAvailabilityChanged: (active) =>
                            _setAvailability(product, active),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerProductCard extends StatelessWidget {
  const _OwnerProductCard({
    required this.product,
    required this.onEdit,
    required this.onArchive,
    required this.onAvailabilityChanged,
  });

  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final ValueChanged<bool> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    final available = product['is_available'] == true;
    final stock = product['stock_quantity'] ?? 0;
    final lowStock = product['low_stock'] == true;
    final image = product['image'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9EEE7)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 70,
              height: 70,
              child: image is String && image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ProductPlaceholder(),
                    )
                  : const _ProductPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FreshKartColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${product['category_name'] ?? 'Category'} · ₹${product['selling_price']}/${product['unit']}',
                  style: const TextStyle(
                    color: FreshKartColors.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lowStock ? 'Low stock · $stock left' : 'Stock · $stock',
                  style: TextStyle(
                    color: lowStock ? Colors.deepOrange : FreshKartColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch.adaptive(
                key: ValueKey('availability-${product['id']}'),
                value: product['is_active'] == true,
                onChanged: onAvailabilityChanged,
                activeTrackColor: FreshKartColors.green,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit product',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Archive product',
                    onPressed: onArchive,
                    icon: const Icon(
                      Icons.archive_outlined,
                      size: 19,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!available)
            const Tooltip(
              message: 'Unavailable to customers',
              child: Icon(Icons.remove_circle_outline, color: Colors.orange),
            ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: FreshKartColors.paleGreen,
    child: Icon(Icons.eco_rounded, color: FreshKartColors.green, size: 30),
  );
}

class _ProductsError extends StatelessWidget {
  const _ProductsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
