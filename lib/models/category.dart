import 'package:flutter/material.dart';

class GroceryCategory {
  const GroceryCategory({
    required this.name,
    required this.illustration,
    required this.backgroundColor,
    required this.accentColor,
    this.id = '',
    this.imageUrl = '',
    this.description = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String illustration;
  final Color backgroundColor;
  final Color accentColor;
  final String imageUrl;
  final String description;
  final bool isActive;
}
