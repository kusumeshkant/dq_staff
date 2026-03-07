import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import '../../domain/usecase/get_store_orders_usecase.dart';
import '../../service_core/auth/session_manager.dart';
import '../order_detail/order_detail_page.dart';
import '../order_detail/order_detail_binding.dart';

class OrdersController extends GetxController {
  final GetStoreOrdersUseCase getStoreOrdersUseCase;
  final GetOrderByIdUseCase getOrderByIdUseCase;

  OrdersController({
    required this.getStoreOrdersUseCase,
    required this.getOrderByIdUseCase,
  });

  final RxList<OrderEntity> orders = <OrderEntity>[].obs;
  final isLoading = false.obs;
  final searchController = TextEditingController();
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadOrders() async {
    final storeId = Get.find<SessionManager>().storeId;
    if (storeId == null) return;

    isLoading.value = true;
    try {
      final result = await getStoreOrdersUseCase.execute(storeId);
      orders.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load orders: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
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

  // Update a single order in the list (called after status change)
  void updateOrderInList(OrderEntity updated) {
    final idx = orders.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      orders[idx] = updated;
      orders.refresh();
    }
  }
}
