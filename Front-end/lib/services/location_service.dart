import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

enum LocationCheckStatus {
  inside,
  outside,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  timeout,
  mocked,
  error,
}

class LocationCheckResult {
  final LocationCheckStatus status;
  final double? distanceMeters;
  final String? message;
  const LocationCheckResult(this.status, {this.distanceMeters, this.message});
}

class LocationService {
  final List<LatLng> officePoints;
  final double radiusMeters;
  const LocationService({required this.officePoints, this.radiusMeters = 120});

  Future<LocationCheckResult> ensureWithinRadius({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          return LocationCheckResult(LocationCheckStatus.permissionDenied, message: 'Izin lokasi ditolak');
        }
      }
      if (perm == LocationPermission.deniedForever) {
        return LocationCheckResult(LocationCheckStatus.permissionPermanentlyDenied, message: 'Izin lokasi ditolak permanen. Buka pengaturan.');
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return LocationCheckResult(LocationCheckStatus.serviceDisabled, message: 'Layanan lokasi / GPS belum aktif');
      }

      Position? last = await Geolocator.getLastKnownPosition();
      Position fresh;
      try {
        fresh = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: timeout);
      } on TimeoutException {
        if (last == null) {
          return LocationCheckResult(LocationCheckStatus.timeout, message: 'Gagal mendapatkan lokasi (timeout)');
        }
        fresh = last; // fallback to last known
      }

      if (fresh.isMocked) {
        return LocationCheckResult(LocationCheckStatus.mocked, message: 'Lokasi terdeteksi spoof / mock');
      }

      final distance = _minDistanceToAnyOffice(fresh);
      if (distance <= radiusMeters) {
        return LocationCheckResult(LocationCheckStatus.inside, distanceMeters: distance);
      }
      return LocationCheckResult(
        LocationCheckStatus.outside,
        distanceMeters: distance,
        message: 'Diluar radius kantor (jarak ${distance.toStringAsFixed(1)} m)',
      );
    } catch (e) {
      return LocationCheckResult(LocationCheckStatus.error, message: 'Kesalahan lokasi: $e');
    }
  }

  double _minDistanceToAnyOffice(Position p) {
    double min = double.infinity;
    for (final o in officePoints) {
      final d = Geolocator.distanceBetween(p.latitude, p.longitude, o.lat, o.lng);
      if (d < min) min = d;
    }
    return min;
  }
}
