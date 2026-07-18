import 'package:geocoding/geocoding.dart';

/// Forward-geocodes a free-text address into (lat, lng). Returns null if the
/// address is empty, can't be resolved, or the platform geocoder is
/// unavailable (no network / not supported).
Future<({double lat, double lng})?> geocodeAddress(String address) async {
  if (address.trim().isEmpty) return null;
  try {
    final results = await locationFromAddress(address.trim());
    if (results.isEmpty) return null;
    final loc = results.first;
    return (lat: loc.latitude, lng: loc.longitude);
  } catch (_) {
    return null;
  }
}
