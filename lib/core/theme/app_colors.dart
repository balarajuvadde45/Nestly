import 'package:flutter/material.dart';

/// Brand palette inspired by food-delivery & marketplace apps.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE23744); // Zomato-like red
  static const Color primaryDark = Color(0xFFC62828);
  static const Color primaryLight = Color(0xFFFFEBEE);
  static const Color secondary = Color(0xFFFC8019); // Swiggy-like orange
  static const Color secondaryLight = Color(0xFFFFF3E0);

  static const Color accent = Color(0xFF2E7D32); // Fresh green
  static const Color accentLight = Color(0xFFE8F5E9);

  static const Color background = Color(0xFFF8F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF696969);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color shadow = Color(0x1A000000);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  static const Color rating = Color(0xFFFFC107);
  static const Color veg = Color(0xFF2E7D32);
  static const Color nonVeg = Color(0xFFD32F2F);

  static const Color discount = Color(0xFF1565C0);
  static const Color freeDelivery = Color(0xFF00897B);

  // Category tints
  static const List<Color> categoryColors = [
    Color(0xFFFFE0B2),
    Color(0xFFFFCDD2),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFE1BEE7),
    Color(0xFFFFF9C4),
    Color(0xFFB2DFDB),
    Color(0xFFF8BBD9),
  ];
}
