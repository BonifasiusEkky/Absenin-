import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../core/network/api_client.dart';

class AssignmentService {
  final ApiClient _api;
  AssignmentService(this._api);

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get(Env.api('/api/assignments'));
    final data = jsonDecode(res.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    throw FormatException('Unexpected assignments response: ${res.body}');
  }

  Future<Map<String, dynamic>> create({
    required String title,
    String? description,
    File? image,
  }) async {
    final files = <http.MultipartFile>[];
    if (image != null) {
      files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final res = await _api.postMultipart(
      Env.api('/api/assignments'),
      fields: {
        'title': title,
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      },
      files: files,
    );

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
