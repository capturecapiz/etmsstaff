import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/employee.dart';
import 'api_client.dart';
import 'push_service.dart';

/// Holds the logged-in employee + token for the app's lifetime, and
/// persists the token in secure storage so staff don't have to log in
/// every time they open the app.
class Session extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'edmate_token';

  String? token;
  Employee? employee;
  final ApiClient api = ApiClient();

  bool get isLoggedIn => token != null;

  Future<void> restore() async {
    final saved = await _storage.read(key: _tokenKey);
    if (saved != null && saved.isNotEmpty) {
      token = saved;
      api.token = saved;
      notifyListeners();
      // Re-confirm this device's push token on every app reopen, not just
      // on a fresh login — FCM can rotate tokens between app runs, and
      // this keeps the server's copy current without needing the
      // employee to log out/in again.
      unawaited(PushService().registerToken(api));
    }
  }

  Future<void> login(String username, String password) async {
    final resp = await api.post('login.php', {
      'username': username,
      'password': password,
    });
    token = resp['token'] as String;
    employee = Employee.fromJson(resp['employee'] as Map<String, dynamic>);
    api.token = token;
    await _storage.write(key: _tokenKey, value: token);
    notifyListeners();
    unawaited(PushService().registerToken(api));
  }

  /// Called after a successful profile_update.php call so every screen
  /// reading Session.employee (Dashboard's header, Profile itself) shows
  /// the new details immediately, without needing a fresh login.
  void updateEmployee(Employee emp) {
    employee = emp;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('logout.php', {});
    } catch (_) {
      // Best-effort — still clear local state even if the server call fails
      // (e.g. no connection right now).
    }
    token = null;
    employee = null;
    api.token = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
