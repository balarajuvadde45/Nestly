import 'package:flutter/material.dart';

/// Marketplace category (home food, pickles, clothes, etc.)
/// Named ShopCategory to avoid clash with Flutter's foundation Category.
class ShopCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final int vendorCount;

  const ShopCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.imageUrl,
    this.vendorCount = 0,
  });
}
