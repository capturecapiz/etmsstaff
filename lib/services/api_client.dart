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
    return _handleResponse(resp);
  }

  /// Same contract as post(), but sends a multipart/form-data request so a
  /// local file (e.g. a new profile photo picked on-device) can be sent
  /// alongside the usual text fields in one request. Mirrors the admin
  /// panel's own photo-upload pages (changeimage.php etc), which also just
  /// expect a single file field in a normal multipart POST.
  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    required String filePath,
    required String fileField,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);
    final body = {...fields};
    if (token != null) body['token'] = token!;
    request.fields.addAll(body);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    http.Response resp;
    try {
      final streamed = await request.send().timeout(AppConfig.requestTimeout);
      resp = await http.Response.fromStream(streamed);
    } catch (e) {
      throw ApiException(
          'Could not reach the server. Check your Wi-Fi and the server address in Settings.');
    }
    return _handleResponse(resp);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
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
