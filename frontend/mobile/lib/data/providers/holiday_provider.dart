import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/env.dart';
import '../../core/network/api_client.dart';

class Holiday {
  final DateTime date;
  final String name;
  final bool isMassLeave;

  Holiday({required this.date, required this.name, required this.isMassLeave});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['date']),
      name: json['name'],
      isMassLeave: json['is_mass_leave'] == 1 || json['is_mass_leave'] == true,
    );
  }
}

class HolidayProvider extends ChangeNotifier {
  List<Holiday> _holidays = [];
  bool _loading = false;

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _loading;

  Future<void> loadHolidays() async {
    _loading = true;
    notifyListeners();

    final api = ApiClient();
    try {
      final res = await api.get(Env.api('/api/holidays'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['ok'] == true) {
          final List list = data['holidays'];
          _holidays = list.map((e) => Holiday.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading holidays: $e');
    } finally {
      api.close();
      _loading = false;
      notifyListeners();
    }
  }

  bool isHoliday(DateTime day) {
    // Weekend check
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return true;
    }

    // Holiday check
    return _holidays.any((h) =>
        h.date.year == day.year &&
        h.date.month == day.month &&
        h.date.day == day.day);
  }

  String? holidayReason(DateTime day) {
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return 'Libur weekend';
    }

    final holiday = _holidays.cast<Holiday?>().firstWhere(
      (h) =>
          h != null &&
          h.date.year == day.year &&
          h.date.month == day.month &&
          h.date.day == day.day,
      orElse: () => null,
    );

    return holiday?.name;
  }
}
