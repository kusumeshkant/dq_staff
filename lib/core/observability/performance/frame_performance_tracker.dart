import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../src/constants/app_config.dart';
import '../analytics_events.dart';
import '../analytics_service.dart';
import '../crashlytics_service.dart';

const _kSlowMs = 16;
const _kJankyMs = 32;
const _kSevereMs = 100;
const _kWindowSize = 120;
const _kReportThreshold = 0.05;

/// Instruments Flutter frame rendering via [SchedulerBinding.addTimingsCallback].
/// No-ops in dev builds.
class FramePerformanceTracker extends GetxService {
  final List<int> _totalMs = [];
  int _slowCount = 0;
  int _jankyCount = 0;

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
      _totalMs.add(totalMs);
      if (totalMs >= _kSlowMs) _slowCount++;
      if (totalMs >= _kJankyMs) _jankyCount++;
      if (totalMs >= _kSevereMs) {
        _breadcrumb('severe_frame: ${totalMs}ms build=${t.buildDuration.inMilliseconds}ms');
      }
    }
    if (_totalMs.length >= _kWindowSize) _flushWindow();
  }

  void _flushWindow() {
    if (_totalMs.isEmpty) return;
    final count = _totalMs.length;
    final jankRate = _jankyCount / count;
    final maxMs = _totalMs.reduce(max);
    final avgMs = _totalMs.reduce((a, b) => a + b) ~/ count;

    if (jankRate >= _kReportThreshold) {
      _breadcrumb(
        'frame_window: count=$count jank=$_jankyCount '
        'rate=${(jankRate * 100).toStringAsFixed(1)}% '
        'max=${maxMs}ms avg=${avgMs}ms',
      );
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logEvent(
          AnalyticsEvents.frameJankDetected,
          parameters: <String, Object>{
            AnalyticsParams.jankyFrameCount: _jankyCount,
            AnalyticsParams.slowFrameCount: _slowCount,
            AnalyticsParams.totalFrameCount: count,
            AnalyticsParams.maxFrameMs: maxMs,
            AnalyticsParams.avgFrameMs: avgMs,
            AnalyticsParams.flavor: AppConfig.flavor,
          },
        );
      }
    }
    _totalMs.clear();
    _slowCount = 0;
    _jankyCount = 0;
  }

  void _breadcrumb(String message) {
    if (!Get.isRegistered<CrashlyticsService>()) return;
    Get.find<CrashlyticsService>().log(message);
  }
}
