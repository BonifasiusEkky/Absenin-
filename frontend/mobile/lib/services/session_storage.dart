import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoredSession {
  final String token;
  final int userId;
  final String name;
  final String email;
  final String backendRole; // employee|hrd
  final String workMode; // wfo|wfh
  final String? jobTitle;

  StoredSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    this.backendRole = 'employee',
    this.workMode = 'wfo',
    this.jobTitle,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'name': name,
        'email': email,
      'backendRole': backendRole,
      'workMode': workMode,
      'jobTitle': jobTitle,
      };

  static StoredSession? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    try {
      return StoredSession(
        token: j['token'] as String,
        userId: (j['userId'] as num).toInt(),
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        backendRole: j['backendRole'] as String? ?? 'employee',
        workMode: j['workMode'] as String? ?? 'wfo',
        jobTitle: j['jobTitle'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static const _key = 'app_session_v1';

  static Future<void> save(StoredSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }

  static Future<StoredSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(j);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
