// Copy this file to env.dart and fill values or use --dart-define at runtime.
// Do NOT commit env.dart if it contains secrets.
class Env {
  // Laravel backend API base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Face microservice (FastAPI) base URL
  static const String faceBaseUrl = String.fromEnvironment(
    'FACE_BASE_URL',
    defaultValue: 'http://127.0.0.1:8001',
  );

  static Uri api(String path, {Map<String, dynamic>? query}) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$p').replace(queryParameters: query);
  }

  static Uri face(String path, {Map<String, dynamic>? query}) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$faceBaseUrl$p').replace(queryParameters: query);
  }

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
