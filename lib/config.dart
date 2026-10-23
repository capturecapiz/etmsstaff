/// Central place to point the app at your ETMS server.
///
/// The PHP API this app talks to lives in `edmate/api/` on the same server
/// as the existing admin/edmate web apps, and reuses the same `etmsdb`
/// database. See API_SETUP.md (shipped alongside this project) for the
/// matching PHP files and the one-time `tblmobile_tokens` migration they
/// need.
class AppConfig {
  /// Example: http://192.168.1.250/edited%20_%20Sunday/backup/edmate/api
  /// (LAN IP so phones on the same office Wi-Fi can reach it — "localhost"
  /// only works from the server machine itself).
  static const String apiBaseUrl = 'http://192.168.1.250/edited%20_%20Sunday/backup/edmate/api';

  static const String appName = 'PTCAO-ETMS';
  static const String appFullName = 'PTCAO Employee Task Management System';
  static const Duration requestTimeout = Duration(seconds: 20);

  /// apiBaseUrl minus its trailing '/edmate/api' — the server's document
  /// root, e.g. http://192.168.1.250/edited%20_%20Sunday/backup. Several
  /// API responses (apiEmployeeToJson's photoUrl, task_detail.php's
  /// attachmentUrl) return a path relative to THIS, not to apiBaseUrl —
  /// see resolveServerUrl below.
  static String get serverRoot {
    const suffix = '/edmate/api';
    return apiBaseUrl.endsWith(suffix)
        ? apiBaseUrl.substring(0, apiBaseUrl.length - suffix.length)
        : apiBaseUrl;
  }
}

/// Turns a server-relative path (e.g. "/edited%20_%20Sunday/backup/
/// employee/uploads/foo.pdf") into an absolute URL the Flutter side can
/// actually load (NetworkImage, url_launcher, etc. all require a full
/// scheme+host URL — a bare path silently fails). Already-absolute URLs
/// are returned unchanged, so this is safe to call defensively.
String? resolveServerUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '${AppConfig.serverRoot}$path';
}
