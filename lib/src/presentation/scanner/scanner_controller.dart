import 'package:dq_staff/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import '../order_detail/order_detail_binding.dart';
import '../order_detail/order_detail_page.dart';

class ScannerController extends GetxController {
  final GetOrderByIdUseCase getOrderByIdUseCase;
  ScannerController({required this.getOrderByIdUseCase});

  final isProcessing = false.obs;
  final RxSet<String> _scanned = <String>{}.obs;

  Future<void> onBarcodeDetected(String code) async {
    if (isProcessing.value || _scanned.contains(code)) return;
    _scanned.add(code);
    isProcessing.value = true;

    try {
      final order = await getOrderByIdUseCase.execute(code);
      if (order == null) {
        Get.snackbar(
          'Not Found',
          'No order found for this QR code.',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        // Allow retry after a delay
        await Future.delayed(const Duration(seconds: 2));
        _scanned.remove(code);
        return;
      }

      // Navigate to order detail and close scanner
      Get.off(
        () => OrderDetailPage(order: order),
        binding: OrderDetailBinding(),
        arguments: order,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to look up order.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      await Future.delayed(const Duration(seconds: 2));
      _scanned.remove(code);
    } finally {
      isProcessing.value = false;
    }
  }
}
