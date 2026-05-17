import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../src/constants/app_config.dart';
import '../analytics_events.dart';
import '../analytics_service.dart';
import '../crashlytics_service.dart';

const _kStallFrameThreshold = 8;
const _kSevereFrameThreshold = _kStallFrameThreshold * 3; // 24
const _kJankyFrameMs = 32;

/// Detects UI stalls — sustained sequences of janky frames.
///
/// Reports exactly one breadcrumb + analytics at the warning threshold (8 frames)
/// and one additional pair at the severe threshold (24 frames). Resets all state
/// when frames recover, so subsequent stall episodes are detected independently.
///
/// No-ops in dev builds.
class AnrDetector extends GetxService {
  int _consecutiveJankyFrames = 0;
  bool _warningSent = false;
  bool _severeSent = false;

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
        _onRecovery();
      }
    }
  }

  void _checkForStall(int lastFrameMs) {
    if (_consecutiveJankyFrames == _kStallFrameThreshold && !_warningSent) {
      _warningSent = true;
      _breadcrumb(
        'ui_stall[warning]: $_consecutiveJankyFrames consecutive janky frames '
        'last=${lastFrameMs}ms',
      );
      _logStallEvent('warning');
    }
    if (_consecutiveJankyFrames == _kSevereFrameThreshold && !_severeSent) {
      _severeSent = true;
      _breadcrumb(
        'ui_stall[severe]: $_consecutiveJankyFrames consecutive janky frames '
        'last=${lastFrameMs}ms',
      );
      _logStallEvent('severe');
    }
  }

  void _onRecovery() {
    if (_consecutiveJankyFrames >= _kStallFrameThreshold) {
      _breadcrumb('ui_stall_end: recovered after $_consecutiveJankyFrames frames');
    }
    _consecutiveJankyFrames = 0;
    _warningSent = false;
    _severeSent = false;
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
        AnalyticsParams.severity: severity,
        AnalyticsParams.consecutiveJankyFrames: _consecutiveJankyFrames,
        AnalyticsParams.flavor: AppConfig.flavor,
      },
    );
  }
}
