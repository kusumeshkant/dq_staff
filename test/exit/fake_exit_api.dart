import 'package:dq_staff/src/domain/entity/exit_entity.dart';
import 'package:dq_staff/src/domain/repo/exit_api.dart';

/// Records every call; each answer can be scripted per test.
class FakeExitApi implements ExitApi {
  ExitResult Function(String code)? onVerify;
  ExitResult Function(String code, List<String> lines, String requestId)? onComplete;
  ExitResult Function(String orderId, String reason, List<String> lines, String requestId)? onCompleteManual;
  List<ExitOrder> open = [];
  Object? throwOnComplete;

  final verifyCalls = <String>[];
  final completeCalls = <(String code, List<String> lines, String requestId)>[];
  final manualCalls = <(String orderId, String reason, List<String> lines, String requestId)>[];
  final clearCalls = <(String orderId, String note)>[];
  int openCalls = 0;

  @override
  Future<ExitResult> verifyExit(String code) async {
    verifyCalls.add(code);
    return onVerify!(code);
  }

  @override
  Future<ExitResult> completeExit({required String code, required List<String> verifiedLineIds, required String requestId}) async {
    completeCalls.add((code, verifiedLineIds, requestId));
    if (throwOnComplete != null) {
      final e = throwOnComplete!;
      throwOnComplete = null;
      throw e;
    }
    return onComplete!(code, verifiedLineIds, requestId);
  }

  @override
  Future<ExitResult> completeManualExit({
    required String orderId,
    required String reason,
    required List<String> verifiedLineIds,
    required String requestId,
  }) async {
    manualCalls.add((orderId, reason, verifiedLineIds, requestId));
    return onCompleteManual!(orderId, reason, verifiedLineIds, requestId);
  }

  @override
  Future<List<ExitOrder>> openPaidOrders() async {
    openCalls++;
    return open;
  }

  @override
  Future<void> clearOrderFlag({required String orderId, required String note}) async {
    clearCalls.add((orderId, note));
  }
}

const qr = 'DQX1:AbCdEfGhIjKlMnOpQrStUv';

ExitOrder order({bool flagged = false, String id = '6ac02873ef56a98ea03e3764', int age = 12}) => ExitOrder(
      id: id,
      storeName: 'DQ UAT Demo Mart',
      grandTotal: 1474.82,
      createdAt: '2026-10-03T10:00:00Z',
      ageMinutes: age,
      hasOpenFlag: flagged,
      flagReason: flagged ? 'wrong_items' : null,
      flaggedBy: flagged ? 'Asha' : null,
      lines: const [
        ExitLine(id: 'L1', barcode: 'SHIRT', name: 'Slim Fit Shirt', color: 'Navy', size: 'M', price: 999, quantity: 1, isManual: true),
        ExitLine(id: 'L2', barcode: 'SOCKS', name: 'Socks', price: 125, quantity: 2),
      ],
    );

ExitResult res(ExitOutcome o, {ExitOrder? ord, String? at, String? by}) =>
    ExitResult(outcome: o, message: 'server says ${o.name}', order: ord, exitedAt: at, exitedByName: by);
