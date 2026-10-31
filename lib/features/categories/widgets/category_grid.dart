import 'package:flutter/material.dart';

import '../../../models/category.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    required this.categories,
    required this.onCategoryTap,
    super.key,
  });

  final List<GroceryCategory> categories;
  final ValueChanged<GroceryCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: ValueKey(categories.map((category) => category.id).join('-')),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 178,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          index: index,
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }
}
