import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(radius: 42, backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, size: 42, color: Color(0xFF005BFF))),
          const SizedBox(height: 12),
          const Center(child: Text('Eky', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 32),
          const ListTile(leading: Icon(Icons.badge_outlined), title: Text('NIP'), subtitle: Text('123456789')),
          const ListTile(leading: Icon(Icons.mail_outline), title: Text('Email'), subtitle: Text('user@example.com')),
          const ListTile(leading: Icon(Icons.logout), title: Text('Keluar')),
        ],
      ),
    );
  }
}
