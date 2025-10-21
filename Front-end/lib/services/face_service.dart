import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/network/api_client.dart';

class FaceService {
  final ApiClient _api;
  FaceService(this._api);

  Future<bool> health() async {
    final res = await _api.get(Env.face('/health'));
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['ok'] == true;
  }

  Future<Map<String, dynamic>> verify({required File reference, required File capture, String? modelName, String? detectorBackend, String? distanceMetric, bool enforceDetection = false, bool align = true, double? threshold}) async {
    final uri = Env.face('/verify');
    final files = <http.MultipartFile>[
      await http.MultipartFile.fromPath('file1', reference.path),
      await http.MultipartFile.fromPath('file2', capture.path),
    ];
    final fields = <String, String>{
      if (modelName != null) 'model_name': modelName,
      if (detectorBackend != null) 'detector_backend': detectorBackend,
      if (distanceMetric != null) 'distance_metric': distanceMetric,
      'enforce_detection': enforceDetection.toString(),
      'align': align.toString(),
      if (threshold != null) 'threshold': threshold.toString(),
    };
    final res = await _api.postMultipart(uri, fields: fields, files: files);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
