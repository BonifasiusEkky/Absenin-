import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Lightweight reverse-geocoding service.
///
/// By default this uses OpenStreetMap Nominatim (no API key). If you prefer
/// Google Maps Geocoding, replace the implementation to call Google's API
/// and provide an API key from config.
class ReverseGeocodingService {
  /// Return a human-friendly area name for the provided [pos].
  /// Attempts to return city/town/village/county/state in that order, otherwise
  /// falls back to the `display_name` returned by the provider.
  static Future<String?> reverseGeocode(Position pos) async {
    try {
      // If Google Maps API key provided via env, prefer Google Geocoding
      final googleKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
      if (googleKey.isNotEmpty) {
        final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=$googleKey&language=id');
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          final Map<String, dynamic> body = json.decode(resp.body);
          final results = body['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            // Prefer locality / sublocality / administrative levels
            for (final res in results) {
              final comps = (res['address_components'] as List<dynamic>?) ?? [];
              String? pick;
              for (final comp in comps) {
                final types = (comp['types'] as List<dynamic>?)?.cast<String>() ?? [];
                if (types.contains('locality') || types.contains('sublocality') || types.contains('administrative_area_level_2') || types.contains('administrative_area_level_1')) {
                  pick = comp['long_name'] as String?;
                  break;
                }
              }
              if (pick != null && pick.isNotEmpty) return pick;
            }
            // Fallback to formatted_address first segment
            final formatted = results.first['formatted_address'] as String?;
            if (formatted != null && formatted.isNotEmpty) return formatted.split(',').first.trim();
          }
        }
      }

      // Fallback: Nominatim OpenStreetMap
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}&accept-language=id');
      final resp = await http.get(url, headers: {
        'User-Agent': 'absenin-app/1.0 (your-email@example.com)'
      });
      if (resp.statusCode != 200) return null;
      final Map<String, dynamic> body = json.decode(resp.body);
      final address = body['address'] as Map<String, dynamic>?;
      if (address != null) {
        final candidates = [
          'city',
          'town',
          'village',
          'hamlet',
          'municipality',
          'county',
          'state',
        ];
        for (final key in candidates) {
          final v = address[key];
          if (v != null && (v as String).isNotEmpty) return v as String;
        }
      }
      final display = body['display_name'] as String?;
      if (display != null && display.isNotEmpty) {
        // Take first segment (before comma) for brevity
        return display.split(',').first.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
