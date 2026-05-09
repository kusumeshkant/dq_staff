import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../presentation/orders/orders_controller.dart';
import '../../presentation/products/products_controller.dart';

class NotificationService extends GetxService {
  // Nullable: only assigned on non-web platforms inside init().
  // Field initializers run before init()'s kIsWeb guard, so platform-specific
  // singletons (FirebaseMessaging.instance, FlutterLocalNotificationsPlugin)
  // must NOT be eagerly created here — they have no web implementation and
  // constructing them on web causes a crash before runApp() is called.
  FirebaseMessaging? _fcm;
  FlutterLocalNotificationsPlugin? _local;

  Future<NotificationService> init() async {
    if (kIsWeb) {
      debugPrint('[DQ-Staff] NotificationService: web — skipping native push setup');
      return this;
    }

    _fcm = FirebaseMessaging.instance;
    _local = FlutterLocalNotificationsPlugin();

    await _fcm!.requestPermission();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local!.initialize(const InitializationSettings(android: android));

    const channel = AndroidNotificationChannel(
      'dq_staff_orders',
      'New Orders',
      description: 'Notifications for new orders',
      importance: Importance.high,
    );
    await _local!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      final notification = msg.notification;
      if (notification != null) {
        _local!.show(
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
      if (msg.data['type'] == 'new_order') _refreshOrders();
    });

    // Background: user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (msg.data['type'] == 'new_order') _refreshOrders();
    });

    return this;
  }

  void _refreshOrders() {
    try { Get.find<OrdersController>().loadOrders(); } catch (_) {}
    try { Get.find<ProductsController>().loadProducts(); } catch (_) {}
  }

  Future<String?> getToken() async {
    if (kIsWeb || _fcm == null) return null;
    return _fcm!.getToken();
  }
}
