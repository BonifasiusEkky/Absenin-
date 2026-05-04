import 'location_service.dart';


class OfficeConfig {
  // Default fallback coordinates (should match backend defaults and office_settings_service.dart)
  static const List<LatLng> officePoints = [
    LatLng(-7.9397675, 112.69277025),
  ];
  static const double radiusMeters = 120; 
}
