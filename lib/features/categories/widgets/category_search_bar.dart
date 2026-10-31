import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';

class CategorySearchBar extends StatelessWidget {
  const CategorySearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEE7)),
        boxShadow: [
          BoxShadow(
            color: FreshKartColors.darkGreen.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        key: const ValueKey('categorySearchField'),
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: FreshKartColors.green,
            size: 22,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('clearCategorySearchButton'),
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          hintText: 'Search categories...',
          hintStyle: const TextStyle(
            color: FreshKartColors.mutedText,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
