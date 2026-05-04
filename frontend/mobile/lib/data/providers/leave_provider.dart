import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../services/leave_service.dart';
import '../models/leave_request.dart';

class LeaveProvider extends ChangeNotifier {
  final List<LeaveRequest> _items = [];
  bool _loading = false;
  String? _error;

  List<LeaveRequest> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final api = ApiClient();
    try {
      final svc = LeaveService(api);
      final list = await svc.list();
      _items
        ..clear()
        ..addAll(list.map((e) => LeaveRequest.fromJson(e)));
      _items.sort((a, b) => (b.createdAt ?? b.startDate).compareTo(a.createdAt ?? a.startDate));
    } catch (e) {
      _error = e.toString();
    } finally {
      api.close();
      _loading = false;
      notifyListeners();
    }
  }

  Future<LeaveRequest?> submit({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    Object? attachmentFile,
  }) async {
    _error = null;
    notifyListeners();

    final api = ApiClient();
    try {
      final svc = LeaveService(api);
      final json = await svc.submit(
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachment: attachmentFile is File ? attachmentFile : null,
      );
      final item = LeaveRequest.fromJson(json);
      _items.insert(0, item);
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      api.close();
    }
  }
}
