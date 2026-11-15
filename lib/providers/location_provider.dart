import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class DeliveryLocation {
  final String area;
  final String city;
  final String pincode;

  /// Coordinates when the location came from the device GPS (so delivery
  /// distance/ETA can use them later); null for manual entry or saved
  /// addresses without coordinates.
  final double? latitude;
  final double? longitude;

  /// Where this value came from: 'gps' | 'manual' | 'saved'.
  final String source;

  const DeliveryLocation({
    required this.area,
    required this.city,
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.source = 'manual',
  });

  String get short => pincode.isEmpty ? '$area, $city' : '$area, $city $pincode';

  Map<String, dynamic> toJson() => {
        'area': area,
        'city': city,
        'pincode': pincode,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        'source': source,
      };

  factory DeliveryLocation.fromJson(Map<String, dynamic> j) => DeliveryLocation(
        area: j['area'] as String? ?? AppConstants.defaultArea,
        city: j['city'] as String? ?? AppConstants.defaultCity,
        pincode: j['pincode'] as String? ?? '',
        latitude: (j['lat'] as num?)?.toDouble(),
        longitude: (j['lng'] as num?)?.toDouble(),
        source: j['source'] as String? ?? 'manual',
      );
}

/// The delivery area the shopper selected on the home header. Persisted so it
/// survives restarts. Checkout still validates the chosen saved address
/// server-side; this drives discovery UI (header, hub context).
class LocationProvider extends ChangeNotifier {
  static const _key = 'tamarin_delivery_location_v1';

  DeliveryLocation _location = DeliveryLocation(
    area: AppConstants.defaultArea,
    city: AppConstants.defaultCity,
  );

  DeliveryLocation get location => _location;

  bool get isDefault =>
      _location.area == AppConstants.defaultArea &&
      _location.city == AppConstants.defaultCity;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _location = DeliveryLocation.fromJson(decoded);
        notifyListeners();
      }
    } catch (_) {
      // Corrupt value — keep defaults.
    }
  }

  Future<void> save(DeliveryLocation value) async {
    _location = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(value.toJson()));
  }
}
