class AppConstants {
  AppConstants._();

  static const String appName = 'Nestly';
  static const String appTagline =
      'Food · Pickles · Clothes · Wisdom — from home to home';
  static const String currency = '₹';
  static const String defaultCity = 'Hyderabad';
  static const String defaultArea = 'Madhapur';

  static const double deliveryFee = 29;
  static const double freeDeliveryMin = 199;
  static const double platformFee = 5;
  static const double gstPercent = 5;

  /// Breakpoint for switching mobile ↔ web layout
  static const double mobileBreakpoint = 700;
  static const double tabletBreakpoint = 1100;
  static const double maxContentWidth = 1280;

  static const Duration splashDuration = Duration(milliseconds: 2200);
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
}
