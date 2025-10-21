import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String name;
  String role;
  String company;
  String email;
  String employeeId;
  int backendUserId; // numeric user id in Laravel backend DB
  String? avatarPath; // local path to avatar image

  UserProvider({
    this.name = 'Bonifasius Ekky',
    this.role = 'Junior Software',
    this.company = 'PT. Naraya Telematika',
    this.email = 'ekky@naraya.co.id',
    this.employeeId = 'NT-001',
    this.backendUserId = 1,
    this.avatarPath,
  });

  void updateAvatar(String? path) {
    avatarPath = path;
    notifyListeners();
  }

  void updateProfile({String? name, String? role, String? company, String? email, String? employeeId, int? backendUserId}) {
    if (name != null) this.name = name;
    if (role != null) this.role = role;
    if (company != null) this.company = company;
    if (email != null) this.email = email;
    if (employeeId != null) this.employeeId = employeeId;
    if (backendUserId != null) this.backendUserId = backendUserId;
    notifyListeners();
  }
}
