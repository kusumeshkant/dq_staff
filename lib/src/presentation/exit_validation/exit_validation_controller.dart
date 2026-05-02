import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import '../../domain/entity/order_entity.dart';

enum ExitValidationState { idle, scanning, loading, approved, rejected }

class ExitValidationController extends GetxController {
  final GetOrderByIdUseCase getOrderByIdUseCase;
  ExitValidationController({required this.getOrderByIdUseCase});

  final state = ExitValidationState.idle.obs;
  final Rx<OrderEntity?> validatedOrder = Rx(null);
  final RxString rejectionReason = ''.obs;
  final RxSet<String> _processed = <String>{}.obs;

  bool get isProcessing => state.value == ExitValidationState.loading;

  void startScanning() {
    state.value = ExitValidationState.scanning;
    validatedOrder.value = null;
    rejectionReason.value = '';
    _processed.clear();
  }

  void reset() {
    state.value = ExitValidationState.idle;
    validatedOrder.value = null;
    rejectionReason.value = '';
    _processed.clear();
  }

  Future<void> onQrDetected(String code) async {
    if (isProcessing || _processed.contains(code)) return;
    _processed.add(code);
    state.value = ExitValidationState.loading;

    try {
      final order = await getOrderByIdUseCase.execute(code);

      if (order == null) {
        rejectionReason.value = 'No order found for this QR code.';
        state.value = ExitValidationState.rejected;
        return;
      }

      if (order.status == 'completed') {
        validatedOrder.value = order;
        state.value = ExitValidationState.approved;
      } else {
        final reason = switch (order.status.toLowerCase()) {
          'pending'   => 'Payment not yet confirmed.',
          'preparing' => 'Order is still being prepared.',
          'ready'     => 'Order ready but not yet collected.',
          'cancelled' => 'This order was cancelled.',
          _           => 'Order status: ${order.status}',
        };
        rejectionReason.value = reason;
        state.value = ExitValidationState.rejected;
      }
    } catch (e) {
      debugPrint('ExitValidation error: $e');
      rejectionReason.value = 'Could not verify order. Check connection.';
      state.value = ExitValidationState.rejected;
    }
  }

  void retryAfterResult() {
    _processed.clear();
    startScanning();
  }
}
