import 'package:flutter/material.dart';

/// Tamarin brand palette — **monochromatic violet**.
///
/// One hue (~248°) in a full tint/shade ramp plus violet-tinted neutrals.
/// Nothing in the UI introduces a second hue, with a single deliberate
/// exception: the FSSAI-mandated veg (green) / non-veg (brown) food marks,
/// which are legally required to stay green/brown.
class AppColors {
  AppColors._();

  // ── Monochromatic violet ramp ──────────────────────────────────────────
  static const Color violet50 = Color(0xFFF4F2FE);
  static const Color violet100 = Color(0xFFE7E3FD);
  static const Color violet200 = Color(0xFFCFC8FB);
  static const Color violet300 = Color(0xFFB0A5F8);
  static const Color violet400 = Color(0xFF9487F4);
  static const Color violet500 = Color(0xFF7C6AF7); // brand anchor
  static const Color violet600 = Color(0xFF6452DB);
  static const Color violet700 = Color(0xFF4F3EC0);
  static const Color violet800 = Color(0xFF3D2F9C);
  static const Color violet900 = Color(0xFF2C2270);
  static const Color violet950 = Color(0xFF1B1445);

  /// Soft violet brand
  static const Color primary = violet500;
  static const Color primaryDark = violet700;
  static const Color primaryLight = violet100;
  static const Color primarySoft = violet50;

  /// Deeper step of the same hue for secondary CTAs
  static const Color secondary = violet600;
  static const Color secondaryLight = violet50;

  /// Emphasis tone of the same hue (replaces the old green accent)
  static const Color accent = violet700;
  static const Color accentLight = violet100;

  /// Violet-tinted canvas
  static const Color background = Color(0xFFF7F6FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF191631);
  static const Color textSecondary = Color(0xFF5A5570);
  static const Color textHint = Color(0xFF9792AC);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE3E1EF);
  static const Color divider = Color(0xFFEEECF8);
  static const Color shadow = Color(0x1A4F3EC0);

  // ── Semantic colors, desaturated to harmonise with the mono ramp ───────
  static const Color success = Color(0xFF4C7A5C);
  static const Color warning = Color(0xFF8A7A3F);
  static const Color error = Color(0xFFB04A4A);
  static const Color info = violet600;

  /// Rating chips use the brand hue instead of amber.
  static const Color rating = violet600;
  static const Color discount = violet600;
  static const Color freeDelivery = violet700;

  // ── FSSAI exception (legally mandated, keep semantic) ──────────────────
  static const Color veg = Color(0xFF2E7D32);
  static const Color nonVeg = Color(0xFF8B3A2E); // FSSAI brown

  /// Category tints — the same violet at descending intensities.
  static const List<Color> categoryColors = [
    violet100,
    violet50,
    Color(0xFFDBD6F8),
    violet200,
    Color(0xFFEFEDFD),
    Color(0xFFE1DDFA),
    Color(0xFFD8D2F7),
    Color(0xFFF0EEFE),
  ];
}
