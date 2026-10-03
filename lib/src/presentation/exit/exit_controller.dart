import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/entity/exit_entity.dart';
import '../../domain/repo/exit_api.dart';
import '../../service_core/auth/session_manager.dart';

enum ExitStage { start, scanning, typing, loading, review, outcome }

/// Exit at the door: scan (or type) the customer's exit QR → check every paid
/// line → complete. The server decides everything (store, single use, own
/// order, flags); this controller only drives the screens.
class ExitController extends GetxController {
  final ExitApi api;
  final bool Function() _isAdmin;

  ExitController({required this.api, bool Function()? isAdmin}) : _isAdmin = isAdmin ?? _sessionIsAdmin;

  static bool _sessionIsAdmin() =>
      Get.isRegistered<SessionManager>() && (Get.find<SessionManager>().currentUser.value?.isAdmin ?? false);

  final stage = ExitStage.start.obs;
  final Rx<ExitResult?> result = Rx<ExitResult?>(null);
  final RxSet<String> ticked = <String>{}.obs;
  final reason = ''.obs;
  final typedError = ''.obs;
  final errorMessage = ''.obs;
  final isSubmitting = false.obs;

  final RxList<ExitOrder> openOrders = <ExitOrder>[].obs;
  final openLoading = false.obs;
  final openError = ''.obs;

  /// The scanned/typed code being exited (QR flow), or null in manual mode.
  String? _code;

  /// The order picked from the open-paid-orders list (manual exit), else null.
  final Rx<ExitOrder?> manualOrder = Rx<ExitOrder?>(null);

  /// One id per review. Reused if Complete is pressed again after a network
  /// failure, so a request that did reach the server is not applied twice.
  String? _requestId;
  @visibleForTesting
  String? get requestId => _requestId;

  bool get isAdmin => _isAdmin();
  bool get isManual => manualOrder.value != null;
  ExitOrder? get order => result.value?.order;

  bool get allTicked {
    final lines = order?.lines ?? const <ExitLine>[];
    return lines.isNotEmpty && lines.every((l) => ticked.contains(l.id));
  }

  static const minReasonLength = 5;
  bool get reasonOk => !isManual || reason.value.trim().length >= minReasonLength;
  bool get canComplete => stage.value == ExitStage.review && allTicked && reasonOk && !isSubmitting.value;

  void startScan() {
    _resetSession();
    stage.value = ExitStage.scanning;
  }

  void startTyping() {
    _resetSession();
    stage.value = ExitStage.typing;
  }

  void backToStart() {
    _resetSession();
    stage.value = ExitStage.start;
  }

  void _resetSession() {
    result.value = null;
    ticked.clear();
    reason.value = '';
    typedError.value = '';
    errorMessage.value = '';
    _code = null;
    manualOrder.value = null;
    _requestId = null;
  }

  Future<void> submitTyped(String raw) async {
    final code = normaliseExitCode(raw);
    if (code == null) {
      typedError.value = 'Enter the code under the customer\'s QR (starts with DQX1:) or a 24-character order id.';
      return;
    }
    await _verify(code);
  }

  /// Camera callback. Ignores anything while not scanning (the camera keeps
  /// firing on the same frame) and anything that is not an exit QR.
  Future<void> onScanned(String raw) async {
    if (stage.value != ExitStage.scanning) return;
    final code = normaliseExitCode(raw);
    if (code == null) {
      errorMessage.value = 'That is not a DQ exit QR.';
      return;
    }
    await _verify(code);
  }

  Future<void> _verify(String code) async {
    stage.value = ExitStage.loading;
    errorMessage.value = '';
    try {
      final r = await api.verifyExit(code);
      _code = code;
      _show(r);
    } catch (e) {
      errorMessage.value = _clean(e);
      stage.value = ExitStage.start;
    }
  }

  void _show(ExitResult r) {
    result.value = r;
    ticked.clear();
    if (r.outcome == ExitOutcome.okToExit) {
      _requestId = newRequestId();
      stage.value = ExitStage.review;
    } else {
      stage.value = ExitStage.outcome;
    }
  }

  /// Manual exit from the open-paid-orders list: same checklist, plus a reason.
  void startManual(ExitOrder o) {
    _resetSession();
    manualOrder.value = o;
    _show(ExitResult(outcome: ExitOutcome.okToExit, message: '', order: o));
  }

  void toggle(String lineId) {
    if (stage.value != ExitStage.review) return;
    ticked.contains(lineId) ? ticked.remove(lineId) : ticked.add(lineId);
  }

  Future<void> complete() async {
    if (!canComplete) return;
    isSubmitting.value = true;
    errorMessage.value = '';
    final lines = order!.lines.map((l) => l.id).toList();
    try {
      final r = isManual
          ? await api.completeManualExit(
              orderId: manualOrder.value!.id,
              reason: reason.value.trim(),
              verifiedLineIds: lines,
              requestId: _requestId!,
            )
          : await api.completeExit(code: _code!, verifiedLineIds: lines, requestId: _requestId!);
      result.value = r.order == null ? ExitResult(
              outcome: r.outcome, message: r.message, order: order, exitedAt: r.exitedAt, exitedByName: r.exitedByName)
          : r;
      stage.value = ExitStage.outcome;
      if (isManual) loadOpenOrders();
    } catch (e) {
      // Stay on the checklist; pressing Complete again reuses the same requestId.
      errorMessage.value = '${_clean(e)} Press Complete exit again.';
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Admin only — the server refuses staff as well; staff never see the button.
  Future<bool> clearFlag(String note) async {
    final o = order;
    if (!isAdmin || o == null) return false;
    if (note.trim().length < 3) {
      errorMessage.value = 'Say how the issue was resolved.';
      return false;
    }
    try {
      await api.clearOrderFlag(orderId: o.id, note: note.trim());
      if (isManual) {
        await loadOpenOrders();
        final fresh = openOrders.firstWhereOrNull((x) => x.id == o.id);
        startManual(fresh ?? o);
      } else {
        await _verify(_code!);
      }
      return true;
    } catch (e) {
      errorMessage.value = _clean(e);
      return false;
    }
  }

  Future<void> loadOpenOrders() async {
    openLoading.value = true;
    openError.value = '';
    try {
      openOrders.assignAll(await api.openPaidOrders());
    } catch (e) {
      openError.value = _clean(e);
    } finally {
      openLoading.value = false;
    }
  }

  static String newRequestId() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(18, (_) => r.nextInt(256))); // 24 chars, A-Za-z0-9_-
  }

  static String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
