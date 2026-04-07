import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  Future<Map<String, dynamic>> checkIn({required DateTime date, required DateTime time, required double latitude, required double longitude, required File photo}) async {
    String d(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    String t(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';

    final res = await _api.postMultipart(
      Env.api('/api/attendances/check-in'),
      fields: {
        'date': d(date),
        'time': t(time),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      files: [await http.MultipartFile.fromPath('photo', photo.path)],
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkOut({required DateTime date, required DateTime time, required double latitude, required double longitude, required File photo, required String activity}) async {
    String d(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    String t(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';

    final res = await _api.postMultipart(
      Env.api('/api/attendances/check-out'),
      fields: {
        'date': d(date),
        'time': t(time),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'activity': activity,
      },
      files: [await http.MultipartFile.fromPath('photo', photo.path)],
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
