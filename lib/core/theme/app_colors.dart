import 'package:flutter/material.dart';

/// Nestly brand palette — light lavender & white (production).
class AppColors {
  AppColors._();

  /// Soft lavender brand
  static const Color primary = Color(0xFF7C6AF7);
  static const Color primaryDark = Color(0xFF5B4BD6);
  static const Color primaryLight = Color(0xFFF0EDFF);
  static const Color primarySoft = Color(0xFFE8E4FF);

  /// Complementary accent (deeper lilac)
  static const Color secondary = Color(0xFF9B8CFF);
  static const Color secondaryLight = Color(0xFFF5F3FF);

  /// Fresh green for veg / success accents
  static const Color accent = Color(0xFF2E7D32);
  static const Color accentLight = Color(0xFFE8F5E9);

  /// White + lavender-tinted canvas
  static const Color background = Color(0xFFF9F8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1523);
  static const Color textSecondary = Color(0xFF5C5670);
  static const Color textHint = Color(0xFF9A94AB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE4E0F0);
  static const Color divider = Color(0xFFEEEAF8);
  static const Color shadow = Color(0x1A5B4BD6);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF5B4BD6);

  static const Color rating = Color(0xFFFFC107);
  static const Color veg = Color(0xFF2E7D32);
  static const Color nonVeg = Color(0xFFD32F2F);

  static const Color discount = Color(0xFF5B4BD6);
  static const Color freeDelivery = Color(0xFF00897B);

  /// Soft category chips (lavender-adjacent pastels)
  static const List<Color> categoryColors = [
    Color(0xFFE8E4FF),
    Color(0xFFF0EDFF),
    Color(0xFFE0F2F1),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFFFF8E1),
  ];
}
