import 'dart:convert';
import '../core/config/env.dart';
import '../core/network/api_client.dart';
import 'session_storage.dart';

class Session {
  final String token;
  final int userId;
  final String name;
  final String email;
  final String backendRole;
  final String workMode;
  final String? jobTitle;
  Session({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.backendRole,
    required this.workMode,
    this.jobTitle,
  });
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
    final session = Session(
      token: token,
      userId: (user['id'] as num).toInt(),
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      backendRole: user['role'] as String? ?? 'employee',
      workMode: user['work_mode'] as String? ?? 'wfo',
      jobTitle: user['job_title'] as String?,
    );
    // Persist minimal session for auto-login
    try {
      await StoredSession.save(StoredSession(
        token: session.token,
        userId: session.userId,
        name: session.name,
        email: session.email,
        backendRole: session.backendRole,
        workMode: session.workMode,
        jobTitle: session.jobTitle,
      ));
    } catch (_) {
      // ignore storage errors
    }
    return session;
  }

  Future<void> logout(String token) async {
    await _api.postJson(Env.api('/api/auth/logout'), {}, headers: {
      'Authorization': 'Bearer $token',
    });
    try {
      await StoredSession.clear();
    } catch (_) {}
  }
}
