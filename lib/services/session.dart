import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/employee.dart';
import 'api_client.dart';

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
