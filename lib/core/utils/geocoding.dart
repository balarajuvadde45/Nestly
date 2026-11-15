import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of turning device coordinates into a usable delivery area.
class ResolvedPlace {
  final String area;
  final String city;
  final String pincode;

  const ResolvedPlace({
    required this.area,
    required this.city,
    required this.pincode,
  });
}

/// Reverse geocoding (coordinates → address).
///
/// Uses OpenStreetMap Nominatim — free, no API key. Swap to Google
/// Geocoding API or MapmyIndia by replacing this one function when you
/// have billing keys (see INTEGRATIONS.md §4).
Future<ResolvedPlace> reverseGeocode(double latitude, double longitude) async {
  final uri = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse'
    '?lat=$latitude&lon=$longitude&format=jsonv2&addressdetails=1&zoom=18',
  );
  final res = await http.get(uri, headers: {
    // Nominatim usage policy requires a descriptive UA.
    'User-Agent': 'tamarin-app/1.0 (support@tamarin.in)',
  }).timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) {
    throw Exception('Geocoding failed (${res.statusCode})');
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final address = (body['address'] as Map<String, dynamic>?) ?? const {};
  String pick(List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  final area = pick([
    'suburb', 'neighbourhood', 'quarter', 'residential', 'road',
    'village', 'town',
  ]);
  final city = pick([
    'city', 'town', 'village', 'municipality', 'state_district', 'state',
  ]);
  final pincode = pick(['postcode']);
  if (area.isEmpty && city.isEmpty) {
    throw Exception('Could not resolve the location name');
  }
  return ResolvedPlace(
    area: area.isNotEmpty ? area : city,
    city: city.isNotEmpty ? city : 'Hyderabad',
    pincode: pincode,
  );
}
