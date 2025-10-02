import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'data/providers/attendance_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Init locale data for Indonesian (both 'id' and fallback) to avoid LocaleDataException.
    await initializeDateFormatting('id');
  } catch (_) {
    // Silently ignore; fallback manual formatter still works where used.
  }
  runApp(const AbsenInApp());
}

class AbsenInApp extends StatelessWidget {
  const AbsenInApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp.router(
        title: 'Absen.In',
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
      ),
    );
  }
}
