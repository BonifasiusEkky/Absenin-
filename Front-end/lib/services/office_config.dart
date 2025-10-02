import 'location_service.dart';

/// Centralized office (or allowed) coordinates configuration.
/// In future this can be loaded from backend / remote config.
class OfficeConfig {
  static const List<LatLng> officePoints = [
    // Jakarta Pusat (dummy)
    LatLng(-6.200000, 106.816666),
  ];
  static const double radiusMeters = 120; // Default allowed radius.
}
