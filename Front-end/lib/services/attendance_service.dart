import 'dart:convert';
import '../core/config/env.dart';
import '../core/network/api_client.dart';

class AttendanceService {
  final ApiClient _api;
  AttendanceService(this._api);

  Future<List<Map<String, dynamic>>> list({String? userId}) async {
    final uri = Env.api('/api/attendances', query: {
      if (userId != null) 'user_id': userId,
    });
    final res = await _api.get(uri);
    final data = jsonDecode(res.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    throw FormatException('Unexpected attendances response: ${res.body}');
  }

  Future<Map<String, dynamic>> checkIn({required String userId, required DateTime date, required DateTime time, double? latitude, double? longitude, double? distanceM}) async {
    String d(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    String t(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
    final body = {
      'user_id': userId,
      'date': d(date),
      'time': t(time),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (distanceM != null) 'distance_m': distanceM,
    };
    final res = await _api.postJson(Env.api('/api/attendances/check-in'), body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkOut({required String userId, required DateTime date, required DateTime time, String? activity}) async {
    String d(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    String t(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
    final body = {
      'user_id': userId,
      'date': d(date),
      'time': t(time),
      if (activity != null && activity.isNotEmpty) 'activity': activity,
    };
    final res = await _api.postJson(Env.api('/api/attendances/check-out'), body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
