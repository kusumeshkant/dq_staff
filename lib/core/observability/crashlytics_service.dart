import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../src/constants/app_config.dart';
import 'models/crash_category.dart';

/// Production-grade crash reporting service.
///
/// In dev builds: errors are printed to the debug console only.
/// In uat/prod: errors are sent to Firebase Crashlytics.
///
/// PII policy: never log phone numbers, raw tokens, emails, or passwords.
/// Only UIDs and store IDs (opaque identifiers) are permitted.
class CrashlyticsService extends GetxService {
  late final FirebaseCrashlytics _crashlytics;

  @override
  void onInit() {
    super.onInit();
    _crashlytics = FirebaseCrashlytics.instance;
    _crashlytics.setCrashlyticsCollectionEnabled(!AppConfig.isDev);
    _crashlytics.setCustomKey('flavor', AppConfig.flavor);
    _crashlytics.setCustomKey('app', 'dq_staff');
  }

  // ── User context ────────────────────────────────────────────────────────────

  Future<void> setUserContext({String? uid, String? storeId, String? role}) async {
    if (uid != null) await _crashlytics.setUserIdentifier(uid);
    if (storeId != null) await _crashlytics.setCustomKey('store_id', storeId);
    if (role != null) await _crashlytics.setCustomKey('role', role);
  }

  Future<void> clearUserContext() async {
    await _crashlytics.setUserIdentifier('');
    await _crashlytics.setCustomKey('store_id', '');
    await _crashlytics.setCustomKey('role', '');
  }

  // ── Breadcrumb logging ──────────────────────────────────────────────────────

  void log(String message) {
    if (AppConfig.isDev) {
      debugPrint('[Crashlytics:breadcrumb] $message');
      return;
    }
    _crashlytics.log(message);
  }

  // ── Error recording ─────────────────────────────────────────────────────────

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    CrashCategory category = CrashCategory.unknown,
    String? reason,
    bool fatal = false,
  }) async {
    if (AppConfig.isDev) {
      debugPrint('[Crashlytics:DEV] [${category.label}] $exception\n$stack');
      return;
    }
    await _crashlytics.setCustomKey('crash_category', category.label);
    await _crashlytics.recordError(
      exception,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (AppConfig.isDev) {
      debugPrint('[Crashlytics:DEV] [widget] ${details.exceptionAsString()}');
      return;
    }
    await _crashlytics.setCustomKey('crash_category', CrashCategory.widget.label);
    await _crashlytics.recordFlutterFatalError(details);
  }
}
