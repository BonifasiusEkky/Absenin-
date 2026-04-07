import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../../core/network/api_client.dart';
import '../../services/assignment_service.dart';

import 'dart:io';

class AssignmentProvider extends ChangeNotifier {
  final List<Assignment> _items = [];
  bool _loading = false;
  String? _error;

  UnmodifiableListView<Assignment> get items => UnmodifiableListView(_items);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final api = ApiClient();
    try {
      final svc = AssignmentService(api);
      final list = await svc.list();
      _items
        ..clear()
        ..addAll(list.map((e) => Assignment.fromJson(e)));
      _items.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    } catch (e) {
      _error = e.toString();
    } finally {
      api.close();
      _loading = false;
      notifyListeners();
    }
  }

  Future<Assignment?> create({required String title, String? description, File? image}) async {
    _error = null;
    notifyListeners();

    final api = ApiClient();
    try {
      final svc = AssignmentService(api);
      final json = await svc.create(title: title, description: description, image: image);
      final item = Assignment.fromJson(json);
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
