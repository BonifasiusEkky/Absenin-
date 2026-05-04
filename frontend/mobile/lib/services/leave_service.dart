import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../core/network/api_client.dart';

class LeaveService {
  final ApiClient _api;
  LeaveService(this._api);

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get(Env.api('/api/leaves'));
    final data = jsonDecode(res.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    throw FormatException('Unexpected leaves response: ${res.body}');
  }

  Future<Map<String, dynamic>> submit({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    File? attachment,
  }) async {
    String d(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    final files = <http.MultipartFile>[];
    if (attachment != null) {
      files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
    }

    final res = await _api.postMultipart(
      Env.api('/api/leaves'),
      fields: {
        'type': type,
        'start_date': d(startDate),
        'end_date': d(endDate),
        'reason': reason,
      },
      files: files,
    );

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
