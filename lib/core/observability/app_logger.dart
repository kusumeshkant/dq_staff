import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../src/constants/app_config.dart';
import 'crashlytics_service.dart';
import 'models/crash_category.dart';

/// Structured, environment-aware logger for dq_staff.
///
/// Dev   → dart:developer.log() with ANSI color channels
/// Prod  → Crashlytics breadcrumbs for errors; suppresses verbose logs
///
/// Log channels (name field in dart:developer):
///   GQL:REQ / GQL:RES / GQL:ERR  — GraphQL request lifecycle
///   AUTH                          — session / token events
///   NAV                           — navigation / routing
///   APP:INFO / APP:WARN / APP:ERR — general application logs
///
/// PII policy: mask tokens, emails, phone numbers before logging.
/// Use [_maskToken] for auth tokens; never log raw Firebase ID tokens.
class AppLogger {
  static const _reset   = '\x1B[0m';
  static const _cyan    = '\x1B[36m';
  static const _green   = '\x1B[32m';
  static const _red     = '\x1B[31m';
  static const _yellow  = '\x1B[33m';
  static const _blue    = '\x1B[34m';
  static const _magenta = '\x1B[35m';

  // ── GraphQL ─────────────────────────────────────────────────────────────────

  static void request(String operation, {Map<String, dynamic>? variables}) {
    if (!AppConfig.isDev) return;
    final vars = (variables != null && variables.isNotEmpty)
        ? '\n  vars: $variables'
        : '';
    dev.log('$_cyan┌─ REQUEST  [$operation]$vars$_reset',
        name: 'GQL:REQ', level: 500);
  }

  static void response(String operation, dynamic data) {
    if (!AppConfig.isDev) return;
    dev.log('$_green└─ RESPONSE [$operation]  data: $data$_reset',
        name: 'GQL:RES', level: 500);
  }

  static void graphqlError(String operation, List<dynamic> errors) {
    final msgs = errors.map((e) => e.message).join('; ');
    _log(level: 1000, color: _red, channel: 'GQL:ERR',
        msg: '└─ GQL ERROR [$operation]  $msgs');
    _breadcrumb('gql_error: $operation $msgs');
  }

  static void networkError(String operation, dynamic exception) {
    _log(level: 1000, color: _red, channel: 'GQL:ERR',
        msg: '└─ NET ERROR [$operation]  $exception');
    _breadcrumb('net_error: $operation');
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  static void auth(String message) {
    _log(level: 500, color: _magenta, channel: 'AUTH', msg: message);
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  static void nav(String route) {
    _log(level: 500, color: _blue, channel: 'NAV', msg: '→ $route');
    _breadcrumb('nav: $route');
  }

  // ── General ─────────────────────────────────────────────────────────────────

  static void info(String tag, String message) {
    _log(level: 500, color: _blue, channel: 'APP:INFO', msg: '[$tag] $message');
  }

  static void warning(String tag, String message) {
    _log(level: 900, color: _yellow, channel: 'APP:WARN', msg: '[$tag] $message');
    _breadcrumb('warn: [$tag] $message');
  }

  static void error(String tag, dynamic err, [StackTrace? stack]) {
    _log(level: 1000, color: _red, channel: 'APP:ERR',
        msg: '[$tag] $err', error: err, stackTrace: stack);
    _recordError(err, stack, tag: tag);
  }

  // ── Token masking (PII safety) ───────────────────────────────────────────────

  static String maskToken(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
  }

  // ── Internal helpers ─────────────────────────────────────────────────────────

  static void _log({
    required int level,
    required String color,
    required String channel,
    required String msg,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    dev.log('$color$msg$_reset',
        name: channel, level: level, error: error, stackTrace: stackTrace);
  }

  static void _breadcrumb(String message) {
    if (!Get.isRegistered<CrashlyticsService>()) return;
    Get.find<CrashlyticsService>().log(message);
  }

  static void _recordError(dynamic err, StackTrace? stack, {required String tag}) {
    if (!Get.isRegistered<CrashlyticsService>()) {
      if (kDebugMode) debugPrint('[AppLogger] CrashlyticsService not registered');
      return;
    }
    Get.find<CrashlyticsService>().recordError(
      err, stack,
      category: CrashCategory.unknown,
      reason: tag,
    );
  }
}
