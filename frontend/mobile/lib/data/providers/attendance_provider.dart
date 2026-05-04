import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../../core/network/api_client.dart';
import '../providers/user_provider.dart';
import '../../services/session_storage.dart';

class AttendanceProvider extends ChangeNotifier {
  final List<AttendanceRecord> _records = [];
  bool _loading = false;
  String? _error;
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  bool get loading => _loading;
  String? get error => _error;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;

  /// Load attendance for current month on first open
  Future<void> loadFromBackend(UserProvider user) async {
    await loadByMonth(user, DateTime.now().year, DateTime.now().month);
  }

  /// Load attendance for a specific month
  Future<void> loadByMonth(UserProvider user, int year, int month) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _currentYear = year;
    _currentMonth = month;
    notifyListeners();
    final api = ApiClient();
    try {
      final stored = await StoredSession.load();
      final token = user.token?.isNotEmpty == true ? user.token : stored?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
      }
      final svc = AttendanceService(api);
      final list = await svc.list(token: token, year: year, month: month);
      _records
        ..clear()
        ..addAll(list.map((e) => AttendanceRecord.fromJson(e)));
      // sort by date desc to mimic backend ordering
      _records.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = e.toString();
    } finally {
      api.close();
      _loading = false;
      notifyListeners();
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

  String getMonthYearLabel(int year, int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[month - 1]} $year';
  }
}
