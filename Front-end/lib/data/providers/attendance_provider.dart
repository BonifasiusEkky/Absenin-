import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../../core/network/api_client.dart';
import '../providers/user_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  final List<AttendanceRecord> _records = [];
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFromBackend(UserProvider user) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiClient();
      final svc = AttendanceService(api);
      final list = await svc.list(userId: user.backendUserId.toString());
      _records
        ..clear()
        ..addAll(list.map((e) => AttendanceRecord.fromJson(e)));
      // sort by date desc to mimic backend ordering
      _records.sort((a, b) => b.date.compareTo(a.date));
      api.close();
    } catch (e) {
      _error = e.toString();
    } finally {
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
}
