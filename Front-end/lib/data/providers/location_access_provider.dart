import 'package:flutter/foundation.dart';
import '../../services/location_service.dart';
import '../../services/office_config.dart';

/// Holds last location verification result so that subsequent routes
/// (e.g., camera screen) can ensure user passed location check first.
class LocationAccessProvider extends ChangeNotifier {
  LocationCheckResult? _lastResult;
  bool _checking = false;

  LocationCheckResult? get lastResult => _lastResult;
  bool get checking => _checking;
  bool get isAuthorized => _lastResult?.status == LocationCheckStatus.inside;

  Future<LocationCheckResult> verify() async {
    if (_checking) return _lastResult ?? const LocationCheckResult(LocationCheckStatus.error, message: 'Sedang memeriksa');
    _checking = true;
    notifyListeners();
    final svc = LocationService(officePoints: OfficeConfig.officePoints, radiusMeters: OfficeConfig.radiusMeters);
    final res = await svc.ensureWithinRadius();
    _lastResult = res;
    _checking = false;
    notifyListeners();
    return res;
  }

  void clear() {
    _lastResult = null;
    notifyListeners();
  }
}
