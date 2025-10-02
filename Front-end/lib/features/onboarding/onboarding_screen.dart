import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;
  final pages = const [
    _ObPage('Selamat datang di Absen.In', 'Pantau kehadiran realtime & mudah'),
    _ObPage('Data terjamin, kerja lebih fokus', 'Keamanan & privasi wajah terenkripsi'),
    _ObPage('Absen cukup dengan wajahmu', 'Scanning presensi cepat tanpa antri'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (i) => setState(() => index = i),
              children: pages,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (i) => _dot(i == index)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  if (index < pages.length - 1) {
                    controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  } else {
                    context.go('/login');
                  }
                },
                child: Text(index == pages.length - 1 ? 'Mulai' : 'Lanjut'),
              ),
            ),
          )
        ]),
      ),
    );
  }
}

Widget _dot(bool active) => AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF005BFF) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );

class _ObPage extends StatelessWidget {
  final String title;
  final String desc;
  const _ObPage(this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: Icon(Icons.face_retouching_natural, size: 120, color: Color(0xFF005BFF))),
          ),
          const SizedBox(height: 40),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
        ],
      ),
    );
  }
}
