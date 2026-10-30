import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';
import '../../../models/category.dart';
import 'category_card.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    required this.categories,
    required this.onCategoryTap,
    this.onSeeAll,
    this.showAll = false,
    super.key,
  });

  final List<GroceryCategory> categories;
  final ValueChanged<GroceryCategory> onCategoryTap;
  final VoidCallback? onSeeAll;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Shop by category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FreshKartColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (!showAll)
                TextButton(
                  key: const ValueKey('seeAllCategoriesButton'),
                  onPressed: onSeeAll ?? () => onCategoryTap(categories.first),
                  style: TextButton.styleFrom(
                    foregroundColor: FreshKartColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          GridView.builder(
            key: const ValueKey('categoryGrid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 104,
              mainAxisSpacing: 10,
              crossAxisSpacing: 9,
            ),
            itemBuilder: (context, index) => CategoryCard(
              category: categories[index],
              index: index,
              onTap: () => onCategoryTap(categories[index]),
            ),
          ),
        ],
      ),
    );
  }
}
