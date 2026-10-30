import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../widgets/bottom_navigation.dart';
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
  final Map<String, int> _cartQuantities = {};
  final Set<String> _favorites = {};
  late final AnimationController _entranceController;
  int _selectedDestination = 0;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _homeScrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  int get _cartItemCount =>
      _cartQuantities.values.fold(0, (total, quantity) => total + quantity);

  void _updateSearch(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _selectCategory(GroceryCategory category) {
    setState(() {
      _selectedCategory = category.name;
      _selectedDestination = 1;
    });
  }

  void _addProduct(GroceryProduct product) {
    setState(() {
      _cartQuantities.update(
        product.name,
        (quantity) => quantity + 1,
        ifAbsent: () => 1,
      );
    });
  }

  void _removeProduct(GroceryProduct product) {
    setState(() {
      final quantity = _cartQuantities[product.name] ?? 0;
      if (quantity <= 1) {
        _cartQuantities.remove(product.name);
      } else {
        _cartQuantities[product.name] = quantity - 1;
      }
    });
  }

  void _toggleFavorite(GroceryProduct product) {
    setState(() {
      if (!_favorites.add(product.name)) {
        _favorites.remove(product.name);
      }
    });
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
    return popularProducts.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _selectedDestination != 1 ||
          _selectedCategory == null ||
          product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
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
        return _buildEmptyDestination(
          key: const ValueKey(4),
          title: 'Your profile',
          description:
              'Profile settings are a placeholder in this sample shopping app.',
          icon: Icons.person_rounded,
          actionLabel: 'Back to home',
          onAction: () => setState(() => _selectedDestination = 0),
        );
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
                onSeeAll: () => setState(() {
                  _selectedCategory = null;
                  _selectedDestination = 1;
                }),
              ),
              const SizedBox(height: 23),
            ],
            ProductSection(
              products: _visibleProducts,
              cartQuantities: _cartQuantities,
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
    final selectedCategory = _selectedCategory;
    final visibleProducts = selectedCategory == null
        ? popularProducts
        : popularProducts
              .where((product) => product.category == selectedCategory)
              .toList();
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.only(top: 14, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 7),
            child: Text(
              selectedCategory == null ? 'Explore categories' : 'Categories',
              style: const TextStyle(
                color: FreshKartColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Find something fresh for every part of your day.',
              style: TextStyle(color: FreshKartColors.mutedText, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          CategorySection(
            key: const ValueKey('allCategoriesSection'),
            categories: groceryCategories,
            showAll: true,
            onSeeAll: () => setState(() {
              _selectedCategory = null;
            }),
            onCategoryTap: (category) {
              setState(() => _selectedCategory = category.name);
            },
          ),
          const SizedBox(height: 22),
          ProductSection(
            products: visibleProducts,
            cartQuantities: _cartQuantities,
            favorites: _favorites,
            onAdd: _addProduct,
            onRemove: _removeProduct,
            onFavoriteTap: _toggleFavorite,
            title: selectedCategory == null
                ? 'Popular products'
                : '$selectedCategory picks',
          ),
        ],
      ),
    );
  }

  Widget _buildCart({required Key key}) {
    final items = popularProducts
        .where((product) => (_cartQuantities[product.name] ?? 0) > 0)
        .toList();
    if (items.isEmpty) {
      return _buildEmptyDestination(
        key: key,
        title: 'Your cart is waiting',
        description:
            'Add a few fresh favourites and they’ll be ready for you here.',
        icon: Icons.shopping_bag_outlined,
        actionLabel: 'Browse groceries',
        onAction: () => setState(() => _selectedDestination = 0),
      );
    }

    final total = items.fold<int>(
      0,
      (sum, product) =>
          sum + product.price * (_cartQuantities[product.name] ?? 0),
    );
    return Column(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 17, 20, 14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Your cart',
                  style: TextStyle(
                    color: FreshKartColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              Text(
                '$_cartItemCount ${_cartItemCount == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = items[index];
              final quantity = _cartQuantities[product.name] ?? 0;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE9EEE7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: product.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        product.illustration,
                        style: const TextStyle(fontSize: 29),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: FreshKartColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.priceLabel}  ·  ₹${product.price * quantity}',
                            style: const TextStyle(
                              color: FreshKartColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: ValueKey('cart-remove-${product.name}'),
                      onPressed: () => _removeProduct(product),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: FreshKartColors.green,
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        color: FreshKartColors.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      key: ValueKey('cart-add-${product.name}'),
                      onPressed: () => _addProduct(product),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: FreshKartColors.green,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 17),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9EEE7))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample total',
                      style: TextStyle(
                        color: FreshKartColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$total',
                      style: const TextStyle(
                        color: FreshKartColors.darkGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Checkout not available',
                style: TextStyle(
                  color: FreshKartColors.mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
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
