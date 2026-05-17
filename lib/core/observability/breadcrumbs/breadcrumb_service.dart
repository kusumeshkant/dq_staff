import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../crashlytics_service.dart';
import 'breadcrumb.dart';

const _kCapacity = 50;

/// Structured, bounded breadcrumb buffer. See dq_app for full documentation.
class BreadcrumbService extends GetxService {
  final Queue<Breadcrumb> _buffer = Queue();

  void add(
    BreadcrumbCategory category,
    String message, {
    Map<String, Object>? metadata,
  }) {
    if (_buffer.length >= _kCapacity) _buffer.removeFirst();
    _buffer.addLast(Breadcrumb(message: message, category: category, metadata: metadata));
    if (kDebugMode) debugPrint('[Breadcrumb] ${_buffer.last.toLogString()}');
  }

  void navigation(String screen) =>
      add(BreadcrumbCategory.navigation, 'nav→$screen');

  void apiCall(String operation, {String? correlationId}) => add(
        BreadcrumbCategory.api,
        'api: $operation',
        metadata: correlationId != null ? {'cid': correlationId} : null,
      );

  void apiError(String operation, String errorMsg, {String? correlationId}) =>
      add(
        BreadcrumbCategory.api,
        'api_err: $operation — $errorMsg',
        metadata: correlationId != null ? {'cid': correlationId} : null,
      );

  void userAction(String action, {Map<String, Object>? metadata}) =>
      add(BreadcrumbCategory.userAction, action, metadata: metadata);

  void auth(String event) => add(BreadcrumbCategory.auth, event);

  void scanner(String event) => add(BreadcrumbCategory.scanner, event);

  List<Breadcrumb> get snapshot => List.unmodifiable(_buffer);
  int get length => _buffer.length;

  Future<void> flushToCrashlytics() async {
    if (!Get.isRegistered<CrashlyticsService>()) return;
    final svc = Get.find<CrashlyticsService>();
    for (final crumb in _buffer) {
      svc.log(crumb.toLogString());
    }
  }
}
