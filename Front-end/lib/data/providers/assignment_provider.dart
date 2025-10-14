import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';

class AssignmentProvider extends ChangeNotifier {
  final List<Assignment> _items = [];

  UnmodifiableListView<Assignment> get items => UnmodifiableListView(_items);

  void addAssignment(Assignment a) {
    _items.insert(0, a);
    notifyListeners();
  }
}
