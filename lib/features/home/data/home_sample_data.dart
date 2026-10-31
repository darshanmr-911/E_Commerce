import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../../../models/product.dart';

const groceryCategories = [
  GroceryCategory(
    name: 'Vegetables',
    illustration: '🥬',
    backgroundColor: Color(0xFFE9F4E6),
    accentColor: Color(0xFF3D824A),
  ),
  GroceryCategory(
    name: 'Fruits',
    illustration: '🍎',
    backgroundColor: Color(0xFFFFEEE3),
    accentColor: Color(0xFFD66C42),
  ),
  GroceryCategory(
    name: 'Dairy',
    illustration: '🥛',
    backgroundColor: Color(0xFFEAF2FC),
    accentColor: Color(0xFF5886BE),
  ),
  GroceryCategory(
    name: 'Rice & Pulses',
    illustration: '🌾',
    backgroundColor: Color(0xFFFFF2D9),
    accentColor: Color(0xFFA5782C),
  ),
  GroceryCategory(
    name: 'Snacks',
    illustration: '🍿',
    backgroundColor: Color(0xFFFFEDEB),
    accentColor: Color(0xFFC65D4D),
  ),
  GroceryCategory(
    name: 'Beverages',
    illustration: '🧃',
    backgroundColor: Color(0xFFE9F5F2),
    accentColor: Color(0xFF398A78),
  ),
  GroceryCategory(
    name: 'Personal Care',
    illustration: '🧴',
    backgroundColor: Color(0xFFF2ECFA),
    accentColor: Color(0xFF8066A8),
  ),
  GroceryCategory(
    name: 'Household',
    illustration: '🧹',
    backgroundColor: Color(0xFFF1F1E9),
    accentColor: Color(0xFF777851),
  ),
];

const popularProducts = [
  GroceryProduct(
    id: 'tomatoes',
    name: 'Tomatoes',
    price: 40,
    unit: 'kg',
    category: 'Vegetables',
    illustration: '🍅',
    backgroundColor: Color(0xFFFFEEEA),
    accentColor: Color(0xFFD75C49),
  ),
  GroceryProduct(
    id: 'potatoes',
    name: 'Potatoes',
    price: 30,
    unit: 'kg',
    category: 'Vegetables',
    illustration: '🥔',
    backgroundColor: Color(0xFFFFF3E2),
    accentColor: Color(0xFFA77B4C),
  ),
  GroceryProduct(
    id: 'onions',
    name: 'Onions',
    price: 35,
    unit: 'kg',
    category: 'Vegetables',
    illustration: '🧅',
    backgroundColor: Color(0xFFF7ECF5),
    accentColor: Color(0xFF9A6387),
  ),
  GroceryProduct(
    id: 'bananas',
    name: 'Bananas',
    price: 60,
    unit: 'dozen',
    category: 'Fruits',
    illustration: '🍌',
    backgroundColor: Color(0xFFFFF5D9),
    accentColor: Color(0xFFBA922C),
  ),
  GroceryProduct(
    id: 'milk',
    name: 'Milk',
    price: 30,
    unit: '500ml',
    category: 'Dairy',
    illustration: '🥛',
    backgroundColor: Color(0xFFEAF3FB),
    accentColor: Color(0xFF5C8BB8),
  ),
  GroceryProduct(
    id: 'basmati-rice',
    name: 'Rice',
    price: 70,
    unit: 'kg',
    category: 'Rice & Pulses',
    illustration: '🌾',
    backgroundColor: Color(0xFFFFF2DB),
    accentColor: Color(0xFFA17C43),
  ),
];

const promoSlides = [
  (
    eyebrow: 'FARM-FRESH PICKS',
    title: 'Freshness at your doorstep!',
    subtitle: 'Get fresh groceries delivered to your home.',
    artwork: '🥬',
  ),
  (
    eyebrow: 'A LITTLE FRUIT JOY',
    title: 'Good food, better days.',
    subtitle: 'Colourful picks for your everyday table.',
    artwork: '🍊',
  ),
  (
    eyebrow: 'DAILY ESSENTIALS',
    title: 'Your pantry, sorted.',
    subtitle: 'Everyday favourites, just a tap away.',
    artwork: '🧺',
  ),
];
