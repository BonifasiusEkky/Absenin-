import 'package:flutter_test/flutter_test.dart';
import 'package:absenin/main.dart';

// Widget tests disesuaikan dengan arsitektur baru aplikasi (Splash -> Onboarding -> Login)
void main() {
  testWidgets('Boot menampilkan Splash lalu pindah ke Onboarding', (tester) async {
    await tester.pumpWidget(const AbsenInApp());

    // Splash text muncul
    expect(find.text('Absen.In'), findsOneWidget);

    // Tunggu animasi / delay 1200ms di SplashScreen
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Halaman onboarding pertama harus tampil (judul pertama)
    expect(find.text('Selamat datang di Absen.In'), findsOneWidget);
    expect(find.text('Mulai'), findsNothing); // belum di halaman terakhir
  });

  testWidgets('Onboarding navigasi sampai Login', (tester) async {
    await tester.pumpWidget(const AbsenInApp());
    await tester.pump(const Duration(milliseconds: 1300)); // lewati splash
    await tester.pumpAndSettle();

    // Klik tombol Lanjut dua kali (3 halaman total)
    final lanjutFinder = find.text('Lanjut');
    expect(lanjutFinder, findsOneWidget);
    await tester.tap(lanjutFinder);
    await tester.pump(const Duration(milliseconds: 350));

    // Halaman kedua -> masih 'Lanjut'
    await tester.tap(find.text('Lanjut'));
    await tester.pump(const Duration(milliseconds: 350));

    // Sekarang tombol berubah jadi 'Mulai'
    expect(find.text('Mulai'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    // Berhasil menuju halaman login
    expect(find.text('Masuk'), findsOneWidget);
  });
}
