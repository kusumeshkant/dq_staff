import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/widgets/app_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../theme/app_theme.dart';
import '../order_detail/order_detail_binding.dart';
import '../order_detail/order_detail_page.dart';
import '../orders/orders_controller.dart';

class CompletedOrdersPage extends StatelessWidget {
  const CompletedOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrdersController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Completed Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final completed = c.completedOrders;

        if (completed.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('No completed orders yet',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Completed orders will appear here',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: c.loadOrders,
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: completed.length,
            itemBuilder: (_, i) => _CompletedOrderCard(
              order: completed[i],
              onTap: () => _openOrder(completed[i]),
            ),
          ),
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

class _CompletedOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _CompletedOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final completedAction = order.staffActions
        .where((a) => a.action == 'completed')
        .lastOrNull;

    return GestureDetector(
      onTap: onTap,
      child: AppGlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.successSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.successBorder),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${_shortId(order.id)}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(order.formattedDate,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 10),

            // Order summary
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: AppTheme.textSecondary, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}  ·  ₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),

            // Completed by staff
            if (completedAction != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      color: AppColors.success, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Completed by: ',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      completedAction.staffName ?? 'Unknown',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: AppColors.success, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'At: ',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    completedAction.formattedTime,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8) : id;
}
