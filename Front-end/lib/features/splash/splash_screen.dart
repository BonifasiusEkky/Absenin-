import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_storage.dart';
import 'package:provider/provider.dart';
import '../../data/providers/user_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // On startup, try to restore stored session and navigate accordingly.
    Future.microtask(() async {
      final stored = await StoredSession.load();
      if (stored != null) {
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
          );
        } catch (_) {}
        context.go('/home');
      } else {
        // No session -> proceed to onboarding
        await Future.delayed(const Duration(milliseconds: 1200));
        if (context.mounted) context.go('/onboarding');
      }
    });
    return const Scaffold(
      body: Center(child: Text('Absen.In', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    );
  }
}
