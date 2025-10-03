import 'location_service.dart';

/// Centralized office (or allowed) coordinates configuration.
/// In future this can be loaded from backend / remote config.
class OfficeConfig {
  static const List<LatLng> officePoints = [
    LatLng(-7.9364416, 112.6259625),
  ];
  static const double radiusMeters = 120; 
}
