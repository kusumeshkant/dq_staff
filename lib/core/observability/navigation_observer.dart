import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'analytics_service.dart';
import 'app_logger.dart';

/// Tracks route changes and forwards screen names to [AnalyticsService].
///
/// Register with GetMaterialApp.navigatorObservers:
/// ```dart
/// navigatorObservers: [AnalyticsNavigatorObserver()],
/// ```
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    // Named routes (Get.toNamed) have a settings.name; anonymous routes fall
    // back to the widget class name stripped of 'Page'/'Screen' suffix noise.
    final name = route.settings.name?.isNotEmpty == true
        ? route.settings.name!
        : _extractName(route);
    if (name == null || name.isEmpty) return;

    AppLogger.nav(name);
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logScreen(name);
    }
  }

  String? _extractName(Route<dynamic> route) {
    final raw = route.settings.name ?? '';
    if (raw.isNotEmpty) return raw;
    // Derive from widget type name for anonymous routes
    final typeName = route.runtimeType.toString();
    return typeName != 'Object' ? typeName : null;
  }
}
