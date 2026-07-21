import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

/// Service that coordinates incoming FCM push notification tokens and creates local notifications.
class NotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  static const String _emergencyChannelId = 'maatriva_emergency_channel';
  static const String _emergencyChannelName = 'MAATRIVA Emergencies';

  /// Requests iOS/Android permissions and initializes notifications listener pipelines.
  Future<void> initialize() async {
    // 1. Request OS permissions
    await _requestPermissions();

    // 2. Configure Android high-priority channel details
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveLocalNotification,
    );

    // Create custom siren notification channel on Android
    final androidNotificationPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidNotificationPlugin != null) {
      await androidNotificationPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _emergencyChannelId,
          _emergencyChannelName,
          description: 'High priority alerts for baby physiological warnings.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    // 3. Register messaging triggers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground notifications handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Deep linking handler when app is clicked from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM notification clicked by caregiver: ${message.data}');
    });
  }

  /// Retrieves client FCM device registration token.
  Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  void _onDidReceiveLocalNotification(NotificationResponse response) {
    print('Local notification clicked: ${response.payload}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _emergencyChannelId,
      _emergencyChannelName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }
}
