import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? '' : 'http://localhost:4000',
  );
  static const publicWebUrl = String.fromEnvironment('PUBLIC_WEB_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const supportUrl = String.fromEnvironment('SUPPORT_URL');
  static String get socketUrl => apiBaseUrl;

  static void validate() {
    if (!kReleaseMode) return;
    for (final value in [
      apiBaseUrl,
      publicWebUrl,
      privacyUrl,
      termsUrl,
      supportUrl,
    ]) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.userInfo.isNotEmpty) {
        throw StateError(
          'Release requires configured HTTPS service and policy URLs.',
        );
      }
    }
  }
}
