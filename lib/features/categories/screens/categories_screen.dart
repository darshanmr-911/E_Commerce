import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/category.dart';
import '../data/categories_sample_data.dart';
import '../widgets/category_grid.dart';
import '../widgets/category_search_bar.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({required this.onCategoryTap, super.key});

  final ValueChanged<GroceryCategory> onCategoryTap;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final AnimationController _entranceController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  List<GroceryCategory> get _visibleCategories => categoryCatalog
      .where(
        (category) =>
            category.isActive &&
            category.name.toLowerCase().contains(_searchQuery),
      )
      .toList();

  void _updateSearch(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories;
    final entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: entrance,
      child: SingleChildScrollView(
        key: const ValueKey('categoriesScroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 19, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Shop by Category',
              style: TextStyle(
                color: FreshKartColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Find everything you need for your home.',
              style: TextStyle(color: FreshKartColors.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 19),
            CategorySearchBar(
              controller: _searchController,
              onChanged: _updateSearch,
              onClear: _clearSearch,
            ),
            const SizedBox(height: 20),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: visibleCategories.isEmpty
                  ? _EmptySearchState(
                      key: const ValueKey('emptyCategorySearch'),
                      onClear: _clearSearch,
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.025),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: CategoryGrid(
                        key: ValueKey(
                          visibleCategories
                              .map((category) => category.id)
                              .join('-'),
                        ),
                        categories: visibleCategories,
                        onCategoryTap: widget.onCategoryTap,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 18),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: FreshKartColors.paleGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: FreshKartColors.green,
              size: 31,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No categories found',
            style: TextStyle(
              color: FreshKartColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try a different search or browse all categories.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FreshKartColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('clearEmptyCategorySearchButton'),
            onPressed: onClear,
            child: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}
