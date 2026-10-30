import 'package:flutter/material.dart';

class GroceryProduct {
  const GroceryProduct({
    required this.name,
    required this.price,
    required this.unit,
    required this.category,
    required this.illustration,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String name;
  final int price;
  final String unit;
  final String category;
  final String illustration;
  final Color backgroundColor;
  final Color accentColor;

  String get priceLabel => '₹$price/$unit';
}
