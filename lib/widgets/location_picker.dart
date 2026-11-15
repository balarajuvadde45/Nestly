import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/geocoding.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

/// Opens the delivery-location flow behind the home header chevron.
///
/// Swiggy/Zomato-style: the user's present location is detected
/// automatically first (GPS → reverse geocoding), then they only add the
/// remaining details — flat/house no, building, nearby landmark — and save.
/// Detection failing (no permission / GPS off) falls back to editable
/// manual fields, never blocking the user.
Future<void> showDeliveryLocationPicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _LocationSheet(),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

enum _DetectState { detecting, done, failed }

class _LocationSheetState extends State<_LocationSheet> {
  final _flat = TextEditingController();
  final _building = TextEditingController();
  final _landmark = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();

  _DetectState _detectState = _DetectState.detecting;
  Position? _position;
  String? _detectNote;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = context.read<LocationProvider>().location;
    _area.text = current.area;
    _city.text = current.city;
    _pincode.text = current.pincode;
    // Detect the present location immediately, like Swiggy/Zomato.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  @override
  void dispose() {
    _flat.dispose();
    _building.dispose();
    _landmark.dispose();
    _area.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  /// GPS → reverse geocode → pre-fill the detected address. The user then
  /// only adds flat no / building / landmark.
  Future<void> _useCurrentLocation() async {
    setState(() {
      _detectState = _DetectState.detecting;
      _error = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are turned off. Enable GPS and retry.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied — enter the area manually.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission is blocked in system settings — enter the area manually.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final place = await reverseGeocode(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _position = position;
        _area.text = place.area;
        _city.text = place.city;
        _pincode.text = place.pincode;
        _detectState = _DetectState.done;
      });
      await context.read<LocationProvider>().save(
            DeliveryLocation(
              area: place.area,
              city: place.city,
              pincode: place.pincode,
              latitude: position.latitude,
              longitude: position.longitude,
              source: 'gps',
            ),
          );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _detectState = _DetectState.failed;
        _detectNote = "Couldn't get a GPS fix in time — confirm the area below.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detectState = _DetectState.failed;
        _detectNote = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _detailsValid {
    if (_flat.text.trim().isEmpty) return false;
    if (_area.text.trim().isEmpty || _city.text.trim().isEmpty) return false;
    final pin = _pincode.text.trim();
    return pin.isEmpty || (pin.length == 6 && int.tryParse(pin) != null);
  }

  String get _composedAddress {
    final parts = [
      _flat.text.trim(),
      if (_building.text.trim().isNotEmpty) _building.text.trim(),
      if (_landmark.text.trim().isNotEmpty) 'Near ${_landmark.text.trim()}',
    ];
    return parts.join(', ');
  }

  /// Signed in → persist as a real address (checkout can select it);
  /// guest → keep it as the browsing location and prompt login later.
  Future<void> _save() async {
    if (!_detailsValid) {
      setState(() => _error = _flat.text.trim().isEmpty
          ? 'Add your flat / house number'
          : 'Check the area, city and pincode');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();
    final place = DeliveryLocation(
      area: _area.text.trim(),
      city: _city.text.trim(),
      pincode: _pincode.text.trim(),
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      source: _position != null ? 'gps' : 'manual',
    );
    await location.save(place);
    if (auth.isLoggedIn) {
      final ok = await auth.saveAddress(
        label: 'Home',
        fullAddress: _composedAddress,
        area: place.area,
        city: place.city,
        pincode: place.pincode,
        landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
        isDefault: (auth.user?.addresses.isEmpty ?? true),
      );
      if (!ok && mounted) {
        setState(() {
          _saving = false;
          _error = auth.error ?? 'Could not save the address. Try again.';
        });
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Delivery location',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_detectState == _DetectState.detecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text(
                      'Getting your current location…',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Detected-location banner (or retry row when detection failed).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _detectState == _DetectState.done
                    ? AppColors.primaryLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _detectState == _DetectState.done
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _detectState == _DetectState.done
                        ? Icons.my_location_rounded
                        : Icons.location_off_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _detectState == _DetectState.done
                          ? 'Current location: ${_area.text.trim()}, ${_city.text.trim()}'
                              '${_pincode.text.trim().isEmpty ? '' : ' ${_pincode.text.trim()}'}'
                          : (_detectNote ?? 'Could not detect your location.'),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  TextButton(
                    onPressed: _useCurrentLocation,
                    child: const Text('Retry GPS'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Add delivery details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _flat,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Flat / House no *',
                hintText: 'e.g. Flat 302, Plot 12',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _building,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Building / Apartment (optional)',
                hintText: 'e.g. Silver Springs Apartments',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _landmark,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nearby landmark (optional)',
                hintText: 'e.g. Near Botanical Garden metro',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _area,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _city,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Pincode',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  auth.isLoggedIn
                      ? 'Save address'
                      : 'Use this location (log in to save)',
                ),
              ),
            ),
            if (!auth.isLoggedIn)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Log in to save addresses for faster checkout.',
                  style:
                      TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
