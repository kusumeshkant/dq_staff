import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../src/constants/app_config.dart';
import '../analytics_events.dart';
import '../analytics_service.dart';
import '../network/correlation_id_service.dart';

/// Tracks release-level health: startup duration, session identity,
/// and version tagging for Crashlytics grouping.
class ReleaseHealthService extends GetxService {
  late final String sessionId;
  late final int _initMs;

  @override
  void onInit() {
    super.onInit();
    _initMs = DateTime.now().millisecondsSinceEpoch;
    sessionId = CorrelationIdService.generate();
    if (!AppConfig.isDev) _tagCrashlytics();
  }

  @override
  void onReady() {
    super.onReady();
    final startupMs = DateTime.now().millisecondsSinceEpoch - _initMs;
    _reportStartup(startupMs);
  }

  void _tagCrashlytics() {
    try {
      FirebaseCrashlytics.instance
        ..setCustomKey('session_id', sessionId)
        ..setCustomKey('app_flavor', AppConfig.flavor)
        ..setCustomKey('is_prod', AppConfig.isProd.toString());
    } catch (e) {
      if (kDebugMode) debugPrint('[ReleaseHealth] Crashlytics tagging failed: $e');
    }
  }

  void _reportStartup(int startupMs) {
    if (kDebugMode) {
      debugPrint('[ReleaseHealth] startup=${startupMs}ms session=$sessionId');
    }
    if (!Get.isRegistered<AnalyticsService>()) return;
    final params = <String, Object>{
      AnalyticsParams.startupMs: startupMs,
      AnalyticsParams.sessionId: sessionId,
      AnalyticsParams.flavor: AppConfig.flavor,
    };
    if (startupMs > 5000) {
      Get.find<AnalyticsService>()
          .logEvent(AnalyticsEvents.slowStartup, parameters: params);
    }
  }
}
