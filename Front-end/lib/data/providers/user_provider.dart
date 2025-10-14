import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String name;
  String role;
  String company;
  String email;
  String employeeId;
  String? avatarPath; // local path to avatar image

  UserProvider({
    this.name = 'Bonifasius Ekky',
    this.role = 'Junior Software',
    this.company = 'PT. Naraya Telematika',
    this.email = 'ekky@naraya.co.id',
    this.employeeId = 'NT-001',
    this.avatarPath,
  });

  void updateAvatar(String? path) {
    avatarPath = path;
    notifyListeners();
  }

  void updateProfile({String? name, String? role, String? company, String? email, String? employeeId}) {
    if (name != null) this.name = name;
    if (role != null) this.role = role;
    if (company != null) this.company = company;
    if (email != null) this.email = email;
    if (employeeId != null) this.employeeId = employeeId;
    notifyListeners();
  }
}
