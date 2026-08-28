/// Runtime configuration for Nestly (API + maps).
///
/// Locked launch defaults (2026-07):
/// soft launch, COD only, Google hidden, Android id `in.nestly.app`,
/// host on Render + Cloudflare Pages (free URLs until a domain is bought).
///
/// Local:
/// ```bash
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
/// flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
/// ```
///
/// Production web:
/// ```bash
/// flutter build web --dart-define=API_BASE_URL=https://YOUR-API.onrender.com
/// ```
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static String get socketUrl => apiBaseUrl;

  /// Soft-launch: do not show Google Sign-In until OAuth is configured.
  static const bool googleSignInEnabled = false;

  /// Soft-launch: Cash on Delivery only (Razorpay later).
  static const bool onlinePaymentsEnabled = false;

  static const String androidApplicationId = 'in.nestly.app';

  /// UAT / production: never fall back to client mock catalog.
  static const bool useMockFallback = false;
}
