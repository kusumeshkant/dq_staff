import 'package:dq_staff/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../domain/usecase/flag_order_issue_usecase.dart';
import '../../domain/usecase/update_order_status_usecase.dart';

class OrderDetailController extends GetxController {
  final UpdateOrderStatusUseCase updateOrderStatusUseCase;
  final FlagOrderIssueUseCase flagOrderIssueUseCase;

  OrderDetailController({
    required this.updateOrderStatusUseCase,
    required this.flagOrderIssueUseCase,
  });

  late final Rx<OrderEntity> order;
  final isUpdating = false.obs;

  // Product checklist: barcode → checked
  final RxMap<String, bool> checkedItems = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    order = Rx<OrderEntity>(Get.arguments as OrderEntity);
    _initChecklist();
  }

  void _initChecklist() {
    for (final item in order.value.items) {
      checkedItems[item.barcode] = false;
    }
  }

  void toggleItem(String barcode) {
    checkedItems[barcode] = !(checkedItems[barcode] ?? false);
  }

  bool get allItemsChecked =>
      checkedItems.isNotEmpty && checkedItems.values.every((v) => v);

  int get checkedCount => checkedItems.values.where((v) => v).length;
  int get totalCount => checkedItems.length;

  Future<void> updateStatus() async {
    final next = order.value.nextStatus;
    if (next == null) return;

    isUpdating.value = true;
    try {
      final updated = await updateOrderStatusUseCase.execute(order.value.id, next);
      order.value = updated;
      // Reset checklist for new status
      _initChecklist();
      Get.snackbar(
        'Status Updated',
        'Order is now ${updated.status}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> flagIssue(String reason, String note) async {
    isUpdating.value = true;
    try {
      final updated = await flagOrderIssueUseCase.execute(
          order.value.id, reason, note);
      order.value = updated;
      Get.snackbar('Issue Flagged', 'Order has been flagged.',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to flag issue.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
    }
  }

  void showFlagDialog() {
    final reasons = [
      ('wrong_items', 'Wrong Items'),
      ('payment_mismatch', 'Payment Mismatch'),
      ('customer_absent', 'Customer Absent'),
      ('other', 'Other'),
    ];

    String selectedReason = reasons.first.$1;
    final noteController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2D42),
          title: const Text('Flag Issue',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason',
                  style: TextStyle(color: Color(0xFFB0C4DE), fontSize: 13)),
              const SizedBox(height: 8),
              ...reasons.map((r) => RadioListTile<String>(
                    value: r.$1,
                    groupValue: selectedReason,
                    onChanged: (v) => setState(() => selectedReason = v!),
                    title: Text(r.$2,
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    activeColor: AppColors.warning,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: const TextStyle(color: Color(0xFFB0C4DE)),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFB0C4DE))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () {
                Get.back();
                flagIssue(selectedReason, noteController.text.trim());
              },
              child: const Text('Flag Issue'),
            ),
          ],
        ),
      ),
    );
  }
}
