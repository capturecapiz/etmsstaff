import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Thin wrapper around the edmate JSON API. Every endpoint is a plain POST
/// with `token` as one of the form fields (kept uniform on purpose — see
/// API_SETUP.md) and always returns `{"ok": true, ...}` or
/// `{"ok": false, "error": "..."}`, mirroring the hardened JSON-endpoint
/// pattern already used throughout this project's admin panel (ob_start +
/// shutdown handler + try/catch, so a PHP fatal never comes back as a blank
/// 200 the app can't explain to the user).
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  String? token;

  ApiClient({this.baseUrl = AppConfig.apiBaseUrl, this.token});

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final body = {...fields};
    if (token != null) body['token'] = token!;

    http.Response resp;
    try {
      resp = await http
          .post(uri, body: body)
          .timeout(AppConfig.requestTimeout);
    } catch (e) {
      throw ApiException(
          'Could not reach the server. Check your Wi-Fi and the server address in Settings.');
    }

    if (resp.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      // Mirrors the project's own lesson (see memory: a stray PHP notice
      // before json_encode corrupts the response) — surface the raw body
      // instead of a generic parse error so a server-side bug is visible.
      throw ApiException(
          'Unexpected response from server (not JSON): ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}');
    }

    if (decoded['ok'] != true) {
      throw ApiException(decoded['error'] as String? ?? 'Request failed.');
    }
    return decoded;
  }
}
