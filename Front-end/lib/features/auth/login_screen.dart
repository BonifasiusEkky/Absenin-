import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../data/providers/user_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Masuk', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Silakan login untuk lanjut', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final api = ApiClient();
                    try {
                      final auth = AuthService(api);
                      final session = await auth.login(email: emailCtrl.text.trim(), password: passCtrl.text);
                      if (!context.mounted) return;
                      // Update UserProvider with backend ID and profile
                      final user = context.read<UserProvider>();
                      user.updateProfile(
                        name: session.name,
                        email: session.email,
                        backendUserId: session.userId,
                      );
                      context.go('/home');
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Login gagal: $e')));
                    } finally {
                      api.close();
                    }
                  },
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
