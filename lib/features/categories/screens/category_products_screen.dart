import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../services/backend_config.dart';
import '../../../services/customer_api_client.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../products/screens/product_details_screen.dart';
import '../../products/widgets/product_grid.dart';
import '../data/categories_sample_data.dart';

enum ProductSort { recommended, priceLowToHigh, priceHighToLow }

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({
    required this.categoryId,
    required this.categoryName,
    required this.cartService,
    required this.favorites,
    required this.onFavoriteTap,
    required this.onDestinationSelected,
    required this.onBuyNow,
    super.key,
  });

  final String categoryId;
  final String categoryName;
  final CartService cartService;
  final Set<String> favorites;
  final ValueChanged<GroceryProduct> onFavoriteTap;
  final ValueChanged<int> onDestinationSelected;
  final void Function(GroceryProduct product, int quantity) onBuyNow;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ProductSort _sort = ProductSort.recommended;
  bool _availableOnly = false;
  bool _isList = false;
  final _customerApi = CustomerApiClient();
  List<GroceryProduct> _backendProducts = [];
  bool _isLoading = freshKartBackendEnabled;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (freshKartBackendEnabled) {
      _loadBackendProducts();
    } else {
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  Future<void> _loadBackendProducts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final products = await _customerApi.fetchProducts(
        categoryName: widget.categoryName,
      );
      if (mounted) {
        setState(() {
          _backendProducts = products;
          _isLoading = false;
        });
      }
    } on CustomerApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.message;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryProduct> get _visibleProducts {
    final source = freshKartBackendEnabled
        ? _backendProducts
        : categorySampleProducts;
    final products = source
        .where(
          (product) =>
              (freshKartBackendEnabled
                  ? product.category.toLowerCase() ==
                        widget.categoryName.toLowerCase()
                  : product.categoryId == widget.categoryId) &&
              product.name.toLowerCase().contains(_query) &&
              (!_availableOnly ||
                  (product.isAvailable && product.stockCount > 0)),
        )
        .toList();
    switch (_sort) {
      case ProductSort.recommended:
        break;
      case ProductSort.priceLowToHigh:
        products.sort(
          (a, b) => a.discountedPricePaise.compareTo(b.discountedPricePaise),
        );
      case ProductSort.priceHighToLow:
        products.sort(
          (a, b) => b.discountedPricePaise.compareTo(a.discountedPricePaise),
        );
    }
    return products;
  }

  void _openProduct(GroceryProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductDetailsScreen(
          product: product,
          cartService: widget.cartService,
          isFavorite: widget.favorites.contains(product.productId),
          isProductFavorite: (item) =>
              widget.favorites.contains(item.productId),
          onFavoriteTap: widget.onFavoriteTap,
          onBuyNow: widget.onBuyNow,
        ),
      ),
    );
  }

  void _toggleFavorite(GroceryProduct product) {
    widget.onFavoriteTap(product);
    setState(() {});
  }

  void _addProduct(GroceryProduct product) {
    try {
      final current = widget.cartService.quantityFor(product);
      widget.cartService.add(
        product,
        quantity: current == 0 ? product.minimumOrderQuantity : 1,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${product.name} added to your cart'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1200),
          ),
        );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const ValueKey('toggleProductView'),
            tooltip: _isList ? 'Show grid' : 'Show list',
            onPressed: () => setState(() => _isList = !_isList),
            icon: Icon(
              _isList ? Icons.grid_view_rounded : Icons.view_list_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: ValueKey('category-products-${widget.categoryId}'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${products.length} products',
                      key: const ValueKey('productCount'),
                      style: const TextStyle(
                        color: Color(0xFF738078),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownButton<ProductSort>(
                    key: const ValueKey('productSort'),
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(14),
                    items: const [
                      DropdownMenuItem(
                        value: ProductSort.recommended,
                        child: Text('Recommended'),
                      ),
                      DropdownMenuItem(
                        value: ProductSort.priceLowToHigh,
                        child: Text('Price: low to high'),
                      ),
                      DropdownMenuItem(
                        value: ProductSort.priceHighToLow,
                        child: Text('Price: high to low'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 10),
                child: Text(
                  '${widget.categoryName} picks',
                  key: const ValueKey('selectedCategoryHeading'),
                  style: const TextStyle(
                    color: Color(0xFF1E3025),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('productSearchField'),
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.categoryName.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('clearProductSearch'),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE9EEE7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE9EEE7)),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  key: const ValueKey('availableProductsOnly'),
                  selected: _availableOnly,
                  label: const Text('In stock only'),
                  onSelected: (value) => setState(() => _availableOnly = value),
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 70),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError case final error?)
                _ApiCatalogError(message: error, onRetry: _loadBackendProducts)
              else if (products.isEmpty)
                const _EmptyProducts()
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedBuilder(
                    key: ValueKey('$_isList-$_sort-$_availableOnly-$_query'),
                    animation: widget.cartService,
                    builder: (context, child) => ProductGrid(
                      products: products,
                      quantityFor: widget.cartService.quantityFor,
                      isFavorite: (product) =>
                          widget.favorites.contains(product.productId),
                      onProductTap: _openProduct,
                      onAdd: _addProduct,
                      onFavoriteTap: _toggleFavorite,
                      isList: _isList,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: 1,
        onDestinationSelected: widget.onDestinationSelected,
      ),
    );
  }
}

class _ApiCatalogError extends StatelessWidget {
  const _ApiCatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 38),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Color(0xFF738078),
          ),
          const SizedBox(height: 10),
          const Text(
            'No products found',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing your search or stock filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
