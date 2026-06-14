import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ─── Background handler (top-level, outside any class) ───────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService._showLocal(
    id: message.hashCode,
    title: message.notification?.title ?? message.data['title'] ?? 'APPTD Union',
    body: message.notification?.body ?? message.data['body'] ?? '',
    payload: message.data['route'] ?? '/',
  );
}

// ─── Android notification channel ────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'apptd_high', 'APPTD Union Alerts',
  description: 'Blogs, circulars and union affairs updates',
  importance: Importance.high,
  enableLights: true,
  enableVibration: true,
  ledColor: Color(0xFFB91C1C),
);

const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
  'apptd_high', 'APPTD Union Alerts',
  channelDescription: 'Blogs, circulars and union affairs updates',
  importance: Importance.high,
  priority: Priority.high,
  icon: '@drawable/ic_notification',
  color: Color(0xFFB91C1C),
  enableLights: true,
  enableVibration: true,
  largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
);

const NotificationDetails _notifDetails = NotificationDetails(android: _androidDetails);

// ─── Service ──────────────────────────────────────────────────────────────────
class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static Function(String route)? onNotificationTap;

  static Future<void> init() async {
    // 1. Request permission (Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Init local notifications — Android only
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    );
    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) onNotificationTap?.call(details.payload!);
      },
    );

    // 3. Create Android notification channel
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((msg) async {
      await _showLocal(
        id: msg.hashCode,
        title: msg.notification?.title ?? msg.data['title'] ?? 'APPTD Union',
        body: msg.notification?.body ?? msg.data['body'] ?? '',
        payload: msg.data['route'] ?? '/',
      );
    });

    // 6. Background tap — app brought to foreground
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final route = msg.data['route'] ?? '/';
      onNotificationTap?.call(route);
    });

    // 7. Terminated tap — app cold-started from notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) onNotificationTap?.call(initial.data['route'] ?? '/');

    // 8. Subscribe to all content-type topics
    await Future.wait([
      _fcm.subscribeToTopic('blogs'),
      _fcm.subscribeToTopic('circulars'),
      _fcm.subscribeToTopic('union_affairs'),
    ]);
  }

  /// Show a local notification — Android only
  static Future<void> _showLocal({required int id, required String title, required String body, String payload = '/'}) async {
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
      payload: payload,
    );
  }

  /// FCM token for targeted server-side push
  static Future<String?> getToken() => _fcm.getToken();
}
