import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';

class AttendanceProvider extends ChangeNotifier {
  final List<AttendanceRecord> _records = [];

  AttendanceProvider() {
    // seed dummy data last 15 days
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      _records.add(AttendanceRecord(
        date: d,
        checkIn: d.subtract(const Duration(hours: -8)).add(const Duration(minutes: 2)),
        checkOut: d.add(const Duration(hours: 17, minutes: 5)),
      ));
    }
  }

  List<AttendanceRecord> get records => List.unmodifiable(_records);

  String formatDate(DateTime d) {
    try {
      return DateFormat('EEEE, dd MMM yyyy', 'id').format(d);
    } catch (_) {
      // Fallback manual formatting if locale data not initialized yet
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']; // DateTime.weekday: Mon=1
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      final dayName = days[d.weekday - 1];
      final monthName = months[d.month - 1];
      final dd = d.day.toString().padLeft(2, '0');
      return '$dayName, $dd $monthName ${d.year}';
    }
  }

  int get presentCount => _records.where((r) => !r.isAbsent && !r.isLeave && !r.isSick).length;
  int get leaveCount => _records.where((r) => r.isLeave).length;
  int get sickCount => _records.where((r) => r.isSick).length;
  int get absentCount => _records.where((r) => r.isAbsent).length;
  int get total => _records.length;

  double get presencePercent => total == 0 ? 0 : presentCount / total;
}
