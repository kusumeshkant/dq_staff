import 'package:get/get.dart';
import '../../data/datasources/remote/permission_remote_ds.dart';
import '../auth/session_manager.dart';

/// Loaded once on HomeBinding.dependencies(), refreshed on access page pull.
/// Controllers check booleans reactively via Obx.
class PermissionService extends GetxService {
  final PermissionRemoteDs _ds;

  PermissionService(this._ds);

  final isLoaded        = false.obs;
  final isLoading       = false.obs;

  final canDiscount           = false.obs;
  final maxDiscountPercent    = 0.0.obs;
  final canEditProductInfo    = false.obs;
  final canAddProduct         = false.obs;
  final canDeleteProduct      = false.obs;
  final canBulkUploadProducts = false.obs;

  Future<void> load() async {
    final storeId = Get.find<SessionManager>().storeId;
    if (storeId == null) return;

    isLoading.value = true;
    isLoaded.value = false;
    // Reset to deny-by-default before async fetch so stale state is never visible.
    _apply(null);
    try {
      final perm = await _ds.getMyPermissions(storeId);
      _apply(perm);
      isLoaded.value = true;
    } catch (_) {
      // Non-fatal: defaults remain false (deny-by-default is safe).
    } finally {
      isLoading.value = false;
    }
  }

  void _apply(Map<String, dynamic>? p) {
    if (p == null) return;
    canDiscount.value           = p['canDiscount'] as bool? ?? false;
    maxDiscountPercent.value    = (p['maxDiscountPercent'] as num?)?.toDouble() ?? 0.0;
    canEditProductInfo.value    = p['canEditProductInfo'] as bool? ?? false;
    canAddProduct.value         = p['canAddProduct'] as bool? ?? false;
    canDeleteProduct.value      = p['canDeleteProduct'] as bool? ?? false;
    canBulkUploadProducts.value = p['canBulkUploadProducts'] as bool? ?? false;
  }
}
