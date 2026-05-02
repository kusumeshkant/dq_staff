import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import '../../domain/usecase/get_store_orders_usecase.dart';
import '../../service_core/auth/session_manager.dart';
import '../order_detail/order_detail_binding.dart';
import '../order_detail/order_detail_page.dart';

class OrdersController extends GetxController {
  final GetStoreOrdersUseCase getStoreOrdersUseCase;
  final GetOrderByIdUseCase getOrderByIdUseCase;

  OrdersController({
    required this.getStoreOrdersUseCase,
    required this.getOrderByIdUseCase,
  });

  // ── Source list (all orders for this store) ───────────────────────────────
  final RxList<OrderEntity> orders = <OrderEntity>[].obs;

  // ── Derived explicit RxLists (updated after every load) ──────────────────
  // Dashboard: pending + preparing + ready only
  final RxList<OrderEntity> activeOrders = <OrderEntity>[].obs;

  // Failed: cancelled or flagged
  final RxList<OrderEntity> failedOrders = <OrderEntity>[].obs;

  // My completed: orders this staff personally completed
  final RxList<OrderEntity> myCompletedOrders = <OrderEntity>[].obs;

  // All completed: every order with status == 'completed' in this store
  final RxList<OrderEntity> completedOrders = <OrderEntity>[].obs;

  final isLoading = false.obs;
  final searchController = TextEditingController();
  final isSearching = false.obs;

  Timer? _pollingTimer;

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get activeCount => activeOrders.length;
  int get failedCount => failedOrders.length;
  int get myCompletedCount => myCompletedOrders.length;
  int get completedCount => completedOrders.length;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _silentRefresh(),
    );
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> _silentRefresh() async {
    final storeId = Get.find<SessionManager>().storeId;
    if (storeId == null) return;
    try {
      final result = await getStoreOrdersUseCase.execute(storeId);
      orders.assignAll(result);
      _updateDerivedLists();
    } catch (_) {}
  }

  Future<void> loadOrders() async {
    final storeId = Get.find<SessionManager>().storeId;
    if (storeId == null) return;

    isLoading.value = true;
    try {
      final result = await getStoreOrdersUseCase.execute(storeId);
      orders.assignAll(result);
      _updateDerivedLists();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load orders: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void _updateDerivedLists() {
    final staffId = Get.find<SessionManager>().staffId;
    final all = orders.toList();

    activeOrders.assignAll(
      all.where((o) =>
          o.status == 'pending' ||
          o.status == 'preparing' ||
          o.status == 'ready'),
    );

    failedOrders.assignAll(
      all.where((o) => o.status == 'cancelled' || o.isFlagged),
    );

    completedOrders.assignAll(
      all.where((o) => o.status == 'completed'),
    );

    if (staffId != null) {
      myCompletedOrders.assignAll(
        all.where((o) => o.staffActions.any(
            (a) => a.staffId == staffId && a.action == 'completed')),
      );
    } else {
      myCompletedOrders.clear();
    }
  }

  Future<void> searchByOrderId() async {
    final orderId = searchController.text.trim();
    if (orderId.isEmpty) return;

    isSearching.value = true;
    try {
      final order = await getOrderByIdUseCase.execute(orderId);
      if (order == null) {
        Get.snackbar('Not Found', 'No order found with that ID.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      _openOrderDetail(order);
    } catch (e) {
      Get.snackbar('Error', 'Order lookup failed.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSearching.value = false;
    }
  }

  void openOrder(OrderEntity order) => _openOrderDetail(order);

  void _openOrderDetail(OrderEntity order) {
    Get.to(
      () => OrderDetailPage(order: order),
      binding: OrderDetailBinding(),
      arguments: order,
    )?.then((_) => loadOrders());
  }

  void updateOrderInList(OrderEntity updated) {
    final idx = orders.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      orders[idx] = updated;
      _updateDerivedLists();
    }
  }
}
