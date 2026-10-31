import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/address.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../services/address_service.dart';
import '../../../services/backend_config.dart';
import '../../../services/cart_service.dart';
import '../../../services/customer_api_client.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../address/screens/address_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../categories/data/categories_sample_data.dart';
import '../../categories/screens/categories_screen.dart';
import '../../categories/screens/category_products_screen.dart';
import '../../checkout/screens/checkout_screen.dart';
import '../../customer/screens/customer_orders_screen.dart';
import '../../owner/screens/owner_portal_screen.dart';
import '../data/home_sample_data.dart';
import '../widgets/category_section.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/product_section.dart';
import '../widgets/promo_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _homeScrollController = ScrollController();
  final _cartService = CartService();
  final _addressService = AddressService();
  final _customerApi = CustomerApiClient();
  final Set<String> _favorites = {};
  List<GroceryProduct> _catalogProducts = freshKartBackendEnabled
      ? []
      : popularProducts;
  String? _catalogError;
  bool _catalogLoading = freshKartBackendEnabled;
  late final AnimationController _entranceController;
  int _selectedDestination = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_handleCartChanged);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    if (freshKartBackendEnabled) _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _homeScrollController.dispose();
    _cartService
      ..removeListener(_handleCartChanged)
      ..dispose();
    _addressService.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Map<String, int> get _cartQuantitiesByName => {
    for (final item in _cartService.items) item.product.name: item.quantity,
  };

  void _handleCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCatalog() async {
    try {
      final products = await _customerApi.fetchProducts();
      if (mounted) {
        setState(() {
          _catalogProducts = products;
          _catalogError = null;
          _catalogLoading = false;
        });
      }
    } on CustomerApiException catch (error) {
      if (mounted) {
        setState(() {
          _catalogProducts = [];
          _catalogError = error.message;
          _catalogLoading = false;
        });
      }
    }
  }

  void _updateSearch(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _selectCategory(GroceryCategory category) {
    final selectedCategory = categoryCatalog.firstWhere(
      (item) => item.name == category.name,
    );
    setState(() => _selectedDestination = 1);
    _openCategoryProducts(selectedCategory);
  }

  void _openCategoryProducts(GroceryCategory category) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            CategoryProductsScreen(
              categoryId: category.id,
              categoryName: category.name,
              cartService: _cartService,
              favorites: _favorites,
              onFavoriteTap: _toggleFavorite,
              onBuyNow: _buyNow,
              onDestinationSelected: (index) {
                Navigator.of(context).pop();
                if (index != 1 && mounted) {
                  setState(() => _selectedDestination = index);
                }
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _addProduct(GroceryProduct product) {
    try {
      final current = _cartService.quantityFor(product);
      _cartService.add(
        product,
        quantity: current == 0 ? product.minimumOrderQuantity : 1,
      );
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  void _removeProduct(GroceryProduct product) {
    final quantity = _cartService.quantityFor(product);
    if (quantity > 0) _cartService.setQuantity(product, quantity - 1);
  }

  void _toggleFavorite(GroceryProduct product) {
    setState(() {
      if (!_favorites.add(product.productId)) {
        _favorites.remove(product.productId);
      }
    });
  }

  void _buyNow(GroceryProduct product, int quantity) {
    try {
      _cartService.add(product, quantity: quantity);
    } on StateError catch (error) {
      _showMessage(error.message);
      return;
    }
    setState(() => _selectedDestination = 2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<DeliveryAddress?> _chooseAddress({
    String continueLabel = 'Continue to Checkout',
  }) {
    return Navigator.of(context).push<DeliveryAddress>(
      MaterialPageRoute(
        builder: (context) => AddressScreen(
          addressService: _addressService,
          continueLabel: continueLabel,
        ),
      ),
    );
  }

  Future<void> _startCheckout() async {
    if (_cartService.items.isEmpty) return;
    final address = _addressService.selectedAddress ?? await _chooseAddress();
    if (!mounted || address == null) return;
    _addressService.select(address.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartService: _cartService,
          address: address,
          customerApi: _customerApi,
          useBackend: freshKartBackendEnabled,
          onEditAddress: () =>
              _chooseAddress(continueLabel: 'Use This Address'),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _shopNow() {
    if (_homeScrollController.hasClients) {
      _homeScrollController.animateTo(
        _homeScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  List<GroceryProduct> get _visibleProducts {
    return _catalogProducts.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();
  }

  Widget _entrance(Widget child, {required Key key}) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      key: key,
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.025, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildDestination(_selectedDestination),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (index) {
          FocusScope.of(context).unfocus();
          setState(() => _selectedDestination = index);
        },
      ),
    );
  }

  Widget _buildDestination(int destination) {
    switch (destination) {
      case 0:
        return _buildHome(key: const ValueKey(0));
      case 1:
        return _buildCategories(key: const ValueKey(1));
      case 2:
        return _buildCart(key: const ValueKey(2));
      case 3:
        if (freshKartBackendEnabled) {
          return CustomerOrdersScreen(
            key: const ValueKey(3),
            api: _customerApi,
          );
        }
        return _buildEmptyDestination(
          key: const ValueKey(3),
          title: 'Your orders',
          description:
              'Your order history will show up here once you start shopping.',
          icon: Icons.receipt_long_rounded,
          actionLabel: 'Explore groceries',
          onAction: () => setState(() => _selectedDestination = 0),
        );
      case 4:
        return _buildProfile(key: const ValueKey(4));
      default:
        return _buildHome(key: const ValueKey(0));
    }
  }

  Widget _buildHome({required Key key}) {
    final hasSearch = _searchQuery.isNotEmpty;
    return _entrance(
      SingleChildScrollView(
        key: const ValueKey('homeScroll'),
        controller: _homeScrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(
              onNotificationTap: () => _showMessage(
                'You’re all caught up. New updates will appear here.',
              ),
            ),
            HomeSearchBar(
              controller: _searchController,
              onChanged: _updateSearch,
            ),
            if (!hasSearch) ...[
              PromoBanner(onShopNow: _shopNow),
              const SizedBox(height: 22),
              CategorySection(
                categories: groceryCategories,
                onCategoryTap: _selectCategory,
                onSeeAll: () => setState(() => _selectedDestination = 1),
              ),
              const SizedBox(height: 23),
            ],
            if (_catalogLoading)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_catalogError case final error?)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadCatalog,
                      child: const Text('Retry catalog'),
                    ),
                  ],
                ),
              )
            else
              ProductSection(
                products: _visibleProducts,
                cartQuantities: _cartQuantitiesByName,
                favorites: _favorites,
                onAdd: _addProduct,
                onRemove: _removeProduct,
                onFavoriteTap: _toggleFavorite,
                title: hasSearch ? 'Search results' : 'Popular products',
              ),
            const SizedBox(height: 22),
          ],
        ),
      ),
      key: key,
    );
  }

  Widget _buildCategories({required Key key}) {
    return CategoriesScreen(key: key, onCategoryTap: _openCategoryProducts);
  }

  Widget _buildCart({required Key key}) {
    return CartScreen(
      key: key,
      cartService: _cartService,
      onContinueShopping: () => setState(() => _selectedDestination = 0),
      onProceedToCheckout: _startCheckout,
    );
  }

  Widget _buildProfile({required Key key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: FreshKartColors.paleGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_rounded,
                size: 40,
                color: FreshKartColors.green,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your FreshKart account or open your separate shop-owner workspace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FreshKartColors.mutedText, height: 1.45),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('openOwnerPortal'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OwnerPortalScreen(),
                ),
              ),
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Shop owner sign in'),
              style: FilledButton.styleFrom(
                backgroundColor: FreshKartColors.green,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedDestination = 0),
              child: const Text('Back to shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDestination({
    required Key key,
    required String title,
    required String description,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: FreshKartColors.paleGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 40, color: FreshKartColors.green),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FreshKartColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FreshKartColors.mutedText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: FreshKartColors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
