/// Runtime configuration for Nestly (API + maps).
///
/// ```bash
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
/// flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
/// ```
///
/// Backend DB credentials live only in `backend/.env`.
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

  /// UAT / production: never fall back to client mock catalog.
  static const bool useMockFallback = false;
}
