import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../services/location_service.dart';
import '../../services/office_settings_service.dart';
import '../../services/session_storage.dart';

/// Holds last location verification result so that subsequent routes
/// (e.g., camera screen) can ensure user passed location check first.
class LocationAccessProvider extends ChangeNotifier {
  LocationCheckResult? _lastResult;
  OfficeSettings? _office;
  String _workMode = 'wfo';
  bool _checking = false;

  LocationCheckResult? get lastResult => _lastResult;
  OfficeSettings? get office => _office;
  bool get checking => _checking;
  bool get isAuthorized {
    final s = _lastResult?.status;
    if (s == LocationCheckStatus.inside) return true;
    if (_workMode == 'wfh' && s == LocationCheckStatus.outside) return true;
    return false;
  }

  Future<LocationCheckResult> verify() async {
    if (_checking) return _lastResult ?? const LocationCheckResult(LocationCheckStatus.error, message: 'Sedang memeriksa');
    _checking = true;
    notifyListeners();

    final api = ApiClient();
    try {
      final session = await StoredSession.load();
      _workMode = session?.workMode ?? 'wfo';

      final office = await OfficeSettingsService(api).fetch();
      _office = office;

      final svc = LocationService(
        officePoints: [LatLng(office.latitude, office.longitude)],
        radiusMeters: office.radiusMeters,
      );
      final res = await svc.ensureWithinRadius();
      _lastResult = res;
      return res;
    } finally {
      _checking = false;
      notifyListeners();
      api.close();
    }
  }

  void clear() {
    _lastResult = null;
    notifyListeners();
  }
}
