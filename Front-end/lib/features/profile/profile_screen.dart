import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/providers/user_provider.dart';

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
          _Tile(label: 'Employee ID', value: user.employeeId, icon: Icons.badge_outlined),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
        ],
      ),
    );
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

  Future<void> _editProfile(BuildContext context) async {
    final user = context.read<UserProvider>();
    final nameCtrl = TextEditingController(text: user.name);
    final roleCtrl = TextEditingController(text: user.role);
    final companyCtrl = TextEditingController(text: user.company);
    final emailCtrl = TextEditingController(text: user.email);
    final idCtrl = TextEditingController(text: user.employeeId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Jabatan', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Perusahaan', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Employee ID', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      context.read<UserProvider>().updateProfile(
                            name: nameCtrl.text.trim(),
                            role: roleCtrl.text.trim(),
                            company: companyCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            employeeId: idCtrl.text.trim(),
                          );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Simpan'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
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
