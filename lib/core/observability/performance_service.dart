import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../src/constants/app_config.dart';

/// Custom trace handle returned by [PerformanceService.startTrace].
///
/// Call [stop] when the measured operation completes.
class PerfTrace {
  final Trace? _trace;
  final String name;
  final Stopwatch _sw;

  PerfTrace._(this._trace, this.name) : _sw = Stopwatch()..start();

  Future<void> putAttribute(String key, String value) async {
    _trace?.putAttribute(key, value);
  }

  Future<void> incrementMetric(String key, int by) async {
    _trace?.incrementMetric(key, by);
  }

  Future<void> stop() async {
    _sw.stop();
    if (_trace != null) {
      await _trace.stop();
    } else {
      debugPrint('[Perf:DEV] $name → ${_sw.elapsedMilliseconds}ms');
    }
  }
}

/// Operation timing and performance monitoring service.
///
/// In dev builds: elapsed times are printed to the debug console.
/// In uat/prod: traces are sent to Firebase Performance Monitoring.
class PerformanceService extends GetxService {
  late final FirebasePerformance _perf;

  @override
  void onInit() {
    super.onInit();
    _perf = FirebasePerformance.instance;
    _perf.setPerformanceCollectionEnabled(!AppConfig.isDev);
  }

  /// Starts a named trace. Call [PerfTrace.stop] when the operation ends.
  Future<PerfTrace> startTrace(String name) async {
    if (AppConfig.isDev) return PerfTrace._(null, name);
    final trace = _perf.newTrace(name);
    await trace.start();
    return PerfTrace._(trace, name);
  }

  /// Records a single HTTP metric (for non-Dio HTTP calls).
  Future<void> recordHttpMetric({
    required String url,
    required HttpMethod method,
    required int statusCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
    int? responseContentType,
  }) async {
    if (AppConfig.isDev) {
      debugPrint('[Perf:DEV] http_metric ${method.name} $url → $statusCode');
      return;
    }
    final metric = _perf.newHttpMetric(url, method);
    await metric.start();
    metric.httpResponseCode = statusCode;
    if (requestPayloadSize != null) metric.requestPayloadSize = requestPayloadSize;
    if (responsePayloadSize != null) metric.responsePayloadSize = responsePayloadSize;
    await metric.stop();
  }

  /// Convenience: time a future and record as a named trace.
  Future<T> timeAsync<T>(String traceName, Future<T> Function() fn) async {
    final trace = await startTrace(traceName);
    try {
      final result = await fn();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.putAttribute('error', 'true');
      await trace.stop();
      rethrow;
    }
  }
}
