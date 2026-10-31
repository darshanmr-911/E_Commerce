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
    this.categoryId,
    this.id = '',
    this.description = '',
    this.imageUrl = '',
    this.stockCount = 20,
    this.discountPercent = 0,
    this.isAvailable = true,
    this.originalPricePaiseOverride,
    this.discountedPricePaiseOverride,
    this.minimumOrderQuantity = 1,
  });

  final String id;
  final String name;
  final int price;
  final String unit;
  final String category;
  final String illustration;
  final Color backgroundColor;
  final Color accentColor;
  final String? categoryId;
  final String description;
  final String imageUrl;
  final int stockCount;
  final int discountPercent;
  final bool isAvailable;
  final int? originalPricePaiseOverride;
  final int? discountedPricePaiseOverride;
  final int minimumOrderQuantity;

  String get productId =>
      id.isNotEmpty ? id : name.toLowerCase().replaceAll(' ', '-');

  int get pricePaise => originalPricePaiseOverride ?? price * 100;

  int get discountedPricePaise =>
      discountedPricePaiseOverride ??
      pricePaise * (100 - discountPercent) ~/ 100;

  String get priceLabel => '₹${_formatPaise(pricePaise)}/$unit';

  String get discountedPriceLabel {
    return '₹${_formatPaise(discountedPricePaise)}/$unit';
  }

  String _formatPaise(int amount) {
    final rupees = amount ~/ 100;
    final paise = amount % 100;
    return paise == 0
        ? '$rupees'
        : '$rupees.${paise.toString().padLeft(2, '0')}';
  }
}
