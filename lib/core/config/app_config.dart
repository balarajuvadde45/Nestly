/// Runtime configuration for API + maps.
///
/// Override at build time:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
/// flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
/// ```
class AppConfig {
  AppConfig._();

  /// Backend base URL (no trailing slash).
  /// - Android emulator → host machine: http://10.0.2.2:4000
  /// - iOS simulator / desktop / chrome on same machine: http://localhost:4000
  /// - Physical device: http://YOUR_LAN_IP:4000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  /// Google Maps API key (same key restricted for Android/iOS/Web as needed).
  /// Leave empty to show a fallback tracking UI without the map SDK.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static String get socketUrl => apiBaseUrl;

  static const bool useMockFallback = true;
}
