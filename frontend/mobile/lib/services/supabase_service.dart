import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';

class SupaService {
  SupabaseClient get client => Supabase.instance.client;

  bool get isReady => Env.hasSupabase && Supabase.instance.client.rest.url.isNotEmpty;

  // Example: simple select to test connectivity. Adjust table name or remove if RLS blocks.
  Future<List<Map<String, dynamic>>> tryFetchAttendances({int limit = 1}) async {
    final res = await client.from('attendances').select().limit(limit);
    // supabase-dart returns List<dynamic>; cast to proper type
    return List<Map<String, dynamic>>.from(res as List);
  }
}
