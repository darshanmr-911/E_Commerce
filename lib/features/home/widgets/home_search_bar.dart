import 'package:flutter/material.dart';

import '../../../freshkart_colors.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE6EBE3)),
          boxShadow: [
            BoxShadow(
              color: FreshKartColors.darkGreen.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          key: const ValueKey('homeSearchField'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search vegetables, fruits, groceries...',
            hintStyle: const TextStyle(color: Color(0xFF9AA59B), fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: FreshKartColors.green,
              size: 22,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('clearSearchButton'),
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: FreshKartColors.mutedText,
                      size: 19,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}
