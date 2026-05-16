import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../src/constants/app_config.dart';
import '../analytics_events.dart';
import '../analytics_service.dart';
import '../crashlytics_service.dart';

const _kStallFrameThreshold = 8;
const _kJankyFrameMs = 32;

/// Detects UI stalls — sustained sequences of janky frames.
/// No-ops in dev builds.
class AnrDetector extends GetxService {
  int _consecutiveJankyFrames = 0;
  bool _stallReportedThisSession = false;

  @override
  void onInit() {
    super.onInit();
    if (AppConfig.isDev) return;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  @override
  void onClose() {
    if (!AppConfig.isDev) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    super.onClose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final totalMs = t.totalSpan.inMilliseconds;
      if (totalMs >= _kJankyFrameMs) {
        _consecutiveJankyFrames++;
        _checkForStall(totalMs);
      } else {
        _consecutiveJankyFrames = 0;
      }
    }
  }

  void _checkForStall(int lastFrameMs) {
    if (_consecutiveJankyFrames < _kStallFrameThreshold) return;
    final severity = _consecutiveJankyFrames >= _kStallFrameThreshold * 3
        ? 'severe'
        : 'warning';
    _breadcrumb(
      'ui_stall[$severity]: '
      '${_consecutiveJankyFrames} consecutive janky frames, '
      'last=${lastFrameMs}ms',
    );
    if (!_stallReportedThisSession ||
        _consecutiveJankyFrames >= _kStallFrameThreshold * 3) {
      _stallReportedThisSession = true;
      _logStallEvent(severity);
    }
  }

  void _breadcrumb(String message) {
    if (!Get.isRegistered<CrashlyticsService>()) return;
    Get.find<CrashlyticsService>().log(message);
    if (kDebugMode) debugPrint('[AnrDetector] $message');
  }

  void _logStallEvent(String severity) {
    if (!Get.isRegistered<AnalyticsService>()) return;
    Get.find<AnalyticsService>().logEvent(
      AnalyticsEvents.anrDetected,
      parameters: <String, Object>{
        'severity': severity,
        'consecutive_janky_frames': _consecutiveJankyFrames,
        AnalyticsParams.flavor: AppConfig.flavor,
      },
    );
  }
}
