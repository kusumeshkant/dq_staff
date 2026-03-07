import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  Future<NotificationService> init() async {
    await _fcm.requestPermission();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: android),
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'dq_staff_orders',
      'New Orders',
      description: 'Notifications for new orders',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      final notification = msg.notification;
      if (notification != null) {
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'dq_staff_orders',
              'New Orders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    return this;
  }

  Future<String?> getToken() => _fcm.getToken();
}
