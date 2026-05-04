import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_storage.dart';
import 'package:provider/provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/location_access_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/config/env.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // On startup, try to restore stored session and navigate accordingly.
    Future.microtask(() async {
      // Initialize location/office settings from backend (runs in background for both logged-in and not)
      try {
        final locationProvider = context.read<LocationAccessProvider>();
        await locationProvider.initialize();
      } catch (_) {}
      final stored = await StoredSession.load();
      if (stored != null) {
        final api = ApiClient();
        var tokenValid = false;
        try {
          await api.get(
            Env.api('/api/me'),
            headers: {'Authorization': 'Bearer ${stored.token}'},
          );
          tokenValid = true;
        } catch (_) {
          tokenValid = false;
        } finally {
          api.close();
        }

        if (tokenValid) {
          // Update user provider with stored info
          try {
            final user = context.read<UserProvider>();
            user.updateProfile(
              name: stored.name,
              email: stored.email,
              backendUserId: stored.userId,
              backendRole: stored.backendRole,
              workMode: stored.workMode,
              role: stored.jobTitle,
              token: stored.token,
            );
          } catch (_) {}
          context.go('/home');
          return;
        }

        try {
          await StoredSession.clear();
        } catch (_) {}
      }

      if (stored == null) {
        // No session -> proceed to onboarding
        await Future.delayed(const Duration(milliseconds: 1200));
        if (context.mounted) context.go('/onboarding');
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) context.go('/login');
      }
    });
    return const Scaffold(
      body: Center(child: Text('Absen.In', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    );
  }
}
