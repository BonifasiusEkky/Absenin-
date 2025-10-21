import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;
  final Duration timeout;
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 30)}) : _client = client ?? http.Client();

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    final res = await _client.get(uri, headers: _baseHeaders(headers)).timeout(timeout);
    _ensureSuccess(res);
    return res;
  }

  Future<http.Response> postJson(Uri uri, Object body, {Map<String, String>? headers}) async {
    final res = await _client
        .post(uri, headers: _baseHeaders(headers, json: true), body: jsonEncode(body))
        .timeout(timeout);
    _ensureSuccess(res);
    return res;
  }

  Future<http.Response> postMultipart(Uri uri, {Map<String, String>? fields, List<http.MultipartFile>? files, Map<String, String>? headers}) async {
    final req = http.MultipartRequest('POST', uri);
    if (fields != null) req.fields.addAll(fields);
    if (files != null) req.files.addAll(files);
    // Ensure we always request JSON to avoid HTML redirect pages
    final mergedHeaders = _baseHeaders(headers);
    req.headers.addAll(mergedHeaders);
    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);
    _ensureSuccess(res);
    return res;
  }

  Map<String, String> _baseHeaders(Map<String, String>? headers, {bool json = false}) {
    final base = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (json) base[HttpHeaders.contentTypeHeader] = 'application/json';
    if (headers != null) base.addAll(headers);
    return base;
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiError(res.statusCode, res.body);
  }

  void close() => _client.close();
}

class ApiError implements Exception {
  final int statusCode;
  final String body;
  ApiError(this.statusCode, this.body);
  @override
  String toString() => 'HTTP $statusCode: $body';
}
