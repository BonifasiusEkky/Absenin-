import 'dart:convert';
import '../core/config/env.dart';
import '../core/network/api_client.dart';

class Session {
  final String token;
  final int userId;
  final String name;
  final String email;
  Session({required this.token, required this.userId, required this.name, required this.email});
}

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<Session> login({required String email, required String password}) async {
    final res = await _api.postJson(Env.api('/api/auth/login'), {
      'email': email,
      'password': password,
    });
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['ok'] != true) {
      throw Exception(body['message'] ?? 'Login gagal');
    }
    final user = body['user'] as Map<String, dynamic>;
    final token = body['token'] as String;
    return Session(
      token: token,
      userId: (user['id'] as num).toInt(),
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
    );
  }

  Future<void> logout(String token) async {
    await _api.postJson(Env.api('/api/auth/logout'), {}, headers: {
      'Authorization': 'Bearer $token',
    });
  }
}
