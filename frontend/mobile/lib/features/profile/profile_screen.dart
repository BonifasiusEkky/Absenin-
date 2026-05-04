import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/providers/user_provider.dart';
import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/session_storage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: user.avatarPath != null
                      ? FileImage(File(user.avatarPath!))
                      : const NetworkImage('https://ui-avatars.com/api/?name=Eky&background=0D8ABC&color=fff') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => _changeAvatar(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          Center(child: Text(user.role, style: TextStyle(color: Colors.grey.shade700))),
          const SizedBox(height: 16),
          _Tile(label: 'Perusahaan', value: user.company, icon: Icons.apartment),
          _Tile(label: 'Email', value: user.email, icon: Icons.email_outlined),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok != true) return;

    final messenger = ScaffoldMessenger.of(context);
    final api = ApiClient();
    try {
      final stored = await StoredSession.load();
      final token = stored?.token;
      if (token != null && token.isNotEmpty) {
        await AuthService(api).logout(token);
      } else {
        await StoredSession.clear();
      }
      if (!context.mounted) return;
      context.go('/login');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    } finally {
      api.close();
    }
  }

  Future<void> _changeAvatar(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (img != null && context.mounted) {
        context.read<UserProvider>().updateAvatar(img.path);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ganti avatar: $e')));
    }
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Tile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
