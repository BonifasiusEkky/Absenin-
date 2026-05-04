import 'dart:convert';

import '../core/config/env.dart';
import '../core/network/api_client.dart';

class OfficeSettings {
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const OfficeSettings({required this.latitude, required this.longitude, required this.radiusMeters});

  factory OfficeSettings.fromJson(Map<String, dynamic> json) {
    return OfficeSettings(
      latitude: (json['office_latitude'] as num?)?.toDouble() ?? -7.9397675,
      longitude: (json['office_longitude'] as num?)?.toDouble() ?? 112.69277025,
      radiusMeters: (json['radius_m'] as num?)?.toDouble() ?? 120.0,
    );
  }
}

class OfficeSettingsService {
  final ApiClient _api;
  OfficeSettingsService(this._api);

  Future<OfficeSettings> fetch() async {
    final res = await _api.get(Env.api('/api/office-settings'));
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return OfficeSettings.fromJson(body);
    }
    throw FormatException('Unexpected office settings response: ${res.body}');
  }
}
