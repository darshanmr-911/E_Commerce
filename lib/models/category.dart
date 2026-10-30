import 'package:flutter/material.dart';

class GroceryCategory {
  const GroceryCategory({
    required this.name,
    required this.illustration,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String name;
  final String illustration;
  final Color backgroundColor;
  final Color accentColor;
}
