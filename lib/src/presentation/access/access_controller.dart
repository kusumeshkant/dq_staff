import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/datasources/remote/permission_remote_ds.dart';
import '../../service_core/auth/session_manager.dart';
import '../../service_core/permission/permission_service.dart';

class AccessController extends GetxController {
  final PermissionRemoteDs _ds;

  AccessController(this._ds);

  // ── My requests list ──────────────────────────────────────────────────────────
  final myRequests     = <Map<String, dynamic>>[].obs;
  final isLoadingReqs  = false.obs;
  final reqsError      = ''.obs;

  // ── Discount code generator ───────────────────────────────────────────────────
  final discountPctCtrl  = TextEditingController();
  final generatedCode    = Rx<Map<String, dynamic>?>( null);
  final isGenerating     = false.obs;

  // ── Request access form ───────────────────────────────────────────────────────
  final selectedRequestType = 'discount'.obs;
  final reasonCtrl          = TextEditingController();
  final discountReqPctCtrl  = TextEditingController();
  final selectedProductPerms = <String>[].obs;
  final isSubmitting         = false.obs;

  String get _storeId => Get.find<SessionManager>().storeId ?? '';

  @override
  void onInit() {
    super.onInit();
    loadMyRequests();
  }

  @override
  void onClose() {
    discountPctCtrl.dispose();
    reasonCtrl.dispose();
    discountReqPctCtrl.dispose();
    super.onClose();
  }

  Future<void> loadMyRequests() async {
    if (_storeId.isEmpty) return;
    isLoadingReqs.value = true;
    reqsError.value = '';
    try {
      myRequests.value = await _ds.getMyRequests(_storeId);
    } catch (e) {
      reqsError.value = e.toString();
    } finally {
      isLoadingReqs.value = false;
    }
  }

  // ── Generate discount code ────────────────────────────────────────────────────

  Future<void> generateCode() async {
    final pctText = discountPctCtrl.text.trim();
    final pct = double.tryParse(pctText);
    final max = Get.find<PermissionService>().maxDiscountPercent.value;

    if (pct == null || pct <= 0) {
      Get.snackbar('Invalid', 'Enter a valid discount percentage.',
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (pct > max) {
      Get.snackbar('Limit Exceeded',
          'Your max approved discount is ${max.toStringAsFixed(0)}%.',
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isGenerating.value = true;
    try {
      final result = await _ds.generateDiscountCode(
        storeId: _storeId,
        discountPercent: pct,
      );
      generatedCode.value = result;
      discountPctCtrl.clear();
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isGenerating.value = false;
    }
  }

  void copyCode() {
    final code = generatedCode.value?['code'] as String?;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar('Copied', 'Code "$code" copied to clipboard.',
        backgroundColor: Colors.green, colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  void clearGeneratedCode() => generatedCode.value = null;

  // ── Request access ────────────────────────────────────────────────────────────

  void toggleProductPerm(String perm) {
    if (selectedProductPerms.contains(perm)) {
      selectedProductPerms.remove(perm);
    } else {
      selectedProductPerms.add(perm);
    }
  }

  Future<void> submitRequest() async {
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('Missing', 'Please provide a reason for your request.',
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final type = selectedRequestType.value;

    if (type == 'discount') {
      final pct = double.tryParse(discountReqPctCtrl.text.trim());
      if (pct == null || pct <= 0) {
        Get.snackbar('Invalid', 'Enter the max discount % you are requesting.',
            backgroundColor: Colors.orange, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    if (type == 'product_edit' && selectedProductPerms.isEmpty) {
      Get.snackbar('Missing', 'Select at least one product permission.',
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSubmitting.value = true;
    try {
      await _ds.requestPermission(
        storeId: _storeId,
        requestType: type,
        reason: reason,
        requestedMaxDiscountPercent: type == 'discount'
            ? double.tryParse(discountReqPctCtrl.text.trim())
            : null,
        requestedProductPerms: type == 'product_edit'
            ? selectedProductPerms.toList()
            : null,
      );
      reasonCtrl.clear();
      discountReqPctCtrl.clear();
      selectedProductPerms.clear();
      Get.snackbar('Submitted', 'Request sent. Your admin will review it shortly.',
          backgroundColor: Colors.green, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      await loadMyRequests();
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }
}
