import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../src/constants/app_config.dart';

/// Screen tracking and event analytics service.
///
/// In dev builds: events are printed to the debug console only.
/// In uat/prod: events are forwarded to Firebase Analytics.
///
/// PII policy: only opaque identifiers (UID, store ID) are permitted
/// as event parameters. Never include names, phone numbers, or emails.
class AnalyticsService extends GetxService {
  late final FirebaseAnalytics _analytics;

  @override
  void onInit() {
    super.onInit();
    _analytics = FirebaseAnalytics.instance;
    _analytics.setAnalyticsCollectionEnabled(!AppConfig.isDev);
  }

  // ── User identity ───────────────────────────────────────────────────────────

  Future<void> setUser({String? uid, String? storeId, String? role}) async {
    if (uid != null) await _analytics.setUserId(id: uid);
    if (storeId != null) await _analytics.setUserProperty(name: 'store_id', value: storeId);
    if (role != null) await _analytics.setUserProperty(name: 'role', value: role);
    await _analytics.setUserProperty(name: 'flavor', value: AppConfig.flavor);
  }

  Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
  }

  // ── Screen tracking ─────────────────────────────────────────────────────────

  Future<void> logScreen(String screenName) async {
    if (AppConfig.isDev) {
      debugPrint('[Analytics:DEV] screen_view → $screenName');
      return;
    }
    await _analytics.logScreenView(screenName: screenName);
  }

  // ── Event logging ───────────────────────────────────────────────────────────

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (AppConfig.isDev) {
      debugPrint('[Analytics:DEV] $name ${parameters ?? {}}');
      return;
    }
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
