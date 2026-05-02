import 'package:dq_staff/widgets/app_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../service_core/auth/session_manager.dart';
import '../../theme/app_theme.dart';
import '../order_detail/order_detail_binding.dart';
import '../order_detail/order_detail_page.dart';
import '../orders/orders_controller.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.find<OrdersController>();
    final session = Get.find<SessionManager>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Obx(() => Text(
              session.staffName != null
                  ? '${session.staffName}\'s Orders'
                  : 'My Orders',
            )),
      ),
      body: Obx(() {
        final myOrders = ordersController.myCompletedOrders;

        if (ordersController.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (myOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text(
                  'No completed orders yet',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Orders you complete will appear here',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: AppGlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${myOrders.length} Order${myOrders.length != 1 ? 's' : ''} Completed',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        Text(
                          'Total: ₹${myOrders.fold(0.0, (sum, o) => sum + o.grandTotal).toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Orders list
            Expanded(
              child: RefreshIndicator(
                onRefresh: ordersController.loadOrders,
                color: AppTheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: myOrders.length,
                  itemBuilder: (_, i) => _MyOrderCard(
                    order: myOrders[i],
                    onTap: () => _openOrder(myOrders[i]),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _openOrder(OrderEntity order) {
    Get.to(
      () => OrderDetailPage(order: order),
      binding: OrderDetailBinding(),
      arguments: order,
    )?.then((_) => Get.find<OrdersController>().loadOrders());
  }
}

class _MyOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _MyOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Find the staff's completed action
    final staffId = Get.find<SessionManager>().staffId;
    final completedAction = order.staffActions
        .where((a) => a.staffId == staffId && a.action == 'completed')
        .lastOrNull;

    return GestureDetector(
      onTap: onTap,
      child: AppGlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Green check
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${_shortId(order.id)}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      if (order.storeCode != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    Colors.teal.withValues(alpha: 0.4)),
                          ),
                          child: Text(order.storeCode!,
                              style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (order.storeName != null)
                    Text(
                      order.storeName!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}  ·  ₹${order.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (completedAction != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 11,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          completedAction.formattedTime,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8) : id;
}
