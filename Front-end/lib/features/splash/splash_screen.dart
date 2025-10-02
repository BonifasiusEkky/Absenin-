import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 1200), () => context.go('/home'));
    return const Scaffold(
      body: Center(child: Text('Absen.In', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    );
  }
}
