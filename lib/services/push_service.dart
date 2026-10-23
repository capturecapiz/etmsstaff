import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

/// Must be a top-level (or static) function, annotated exactly like this,
/// per firebase_messaging's requirements for background message handling.
/// It doesn't need to do anything itself: every push this app's server
/// sends (includes/fcm-sender.php) includes a "notification" payload, and
/// Android shows that automatically — using the channel id and icon
/// declared in AndroidManifest.xml — whenever the app is backgrounded or
/// fully closed. This handler just has to exist and be registered for
/// that system-level delivery path to work on recent Android versions.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Push notifications (Firebase Cloud Messaging) for new tasks, daily
/// reminders, task replies and announcements — see includes/fcm-sender.php
/// on the server for the sending side. Fails soft at every step: until
/// android/app/google-services.json is added (Firebase Console setup) and
/// a real Firebase project exists, this class quietly does nothing instead
/// of crashing the app, same as every other not-yet-configured feature in
/// this project.
class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // Must match the channel id in AndroidManifest.xml's
  // com.google.firebase.messaging.default_notification_channel_id meta-data
  // — that's what background/terminated FCM notifications use, and this is
  // what foreground notifications use, so both look and sound identical.
  static const _channel = AndroidNotificationChannel(
    'etms_staff_channel',
    'ETMS Staff Notifications',
    description: 'New tasks, reminders, replies and announcements from ETMS.',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // No google-services.json yet, or Firebase isn't set up on this
      // build — leave _ready false and every other method below becomes
      // a no-op.
      return;
    }

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Permission prompt failing/being denied shouldn't block anything
      // else below — tokens can still be issued, they just won't surface
      // as visible notifications until the user grants it in Settings.
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // While the app is open and in the foreground, FCM does NOT show a
    // system notification on its own — Android only auto-displays
    // notification-payload messages when the app is backgrounded or
    // closed. This is what actually produces the heads-up popup + sound
    // for a staff member actively using the app right now.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });

    _ready = true;
  }

  /// Fetches this device's current FCM token and registers it against the
  /// logged-in employee (see edmate/api/push_register.php), so the server
  /// knows where to push to. Call after login and whenever a session is
  /// restored on app start. Safe to call even if init() never completed.
  Future<void> registerToken(ApiClient api) async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.post('push_register.php', {'fcmToken': token});
      }
    } catch (_) {
      // Best-effort, same as Session.logout()'s server call — a
      // registration hiccup should never block the screen that
      // triggered it.
    }

    // FCM can hand out a new token later (app reinstall, cleared data,
    // token rotation) — keep the server copy current when that happens.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await api.post('push_register.php', {'fcmToken': newToken});
      } catch (_) {}
    });
  }
}
