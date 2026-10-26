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

  /// Just the scheme + host (+ port, if any) from apiBaseUrl — e.g.
  /// http://192.168.1.250 — with NO path on it at all.
  ///
  /// This was previously computed as "apiBaseUrl minus its trailing
  /// /edmate/api", which left .../edited%20_%20Sunday/backup on the end.
  /// That was wrong: apiEmployeeToJson's photoUrl and task_detail.php's
  /// attachmentUrl already come back as a FULL path from the web root
  /// (e.g. "/edited%20_%20Sunday/backup/employee/images/foo.jpg" — see
  /// those PHP files), so prepending the old serverRoot duplicated that
  /// whole "/edited%20_%20Sunday/backup" segment and produced a URL that
  /// could never resolve (silently, for NetworkImage — it just fell back
  /// to the initials avatar — but loudly for url_launcher opening a task
  /// attachment, which is how this got noticed: "could not reach").
  static String get serverRoot {
    final uri = Uri.parse(apiBaseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
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
