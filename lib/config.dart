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

  static const String appName = 'ETMS Staff';
  static const Duration requestTimeout = Duration(seconds: 20);
}
