import '../entity/exit_entity.dart';

/// The backend's exit operations. Every call is checked server-side (role,
/// store, single use); the app only presents the result.
abstract class ExitApi {
  Future<ExitResult> verifyExit(String code);

  Future<ExitResult> completeExit({
    required String code,
    required List<String> verifiedLineIds,
    required String requestId,
  });

  Future<ExitResult> completeManualExit({
    required String orderId,
    required String reason,
    required List<String> verifiedLineIds,
    required String requestId,
  });

  Future<List<ExitOrder>> openPaidOrders();

  /// Admin only (the server refuses staff).
  Future<void> clearOrderFlag({required String orderId, required String note});
}
