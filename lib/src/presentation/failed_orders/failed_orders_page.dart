import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/src/utils/responsive/responsive.dart';
import 'package:dq_staff/widgets/app_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../theme/app_theme.dart';
import '../order_detail/order_detail_binding.dart';
import '../order_detail/order_detail_page.dart';
import '../orders/orders_controller.dart';

class FailedOrdersPage extends StatelessWidget {
  const FailedOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrdersController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Failed Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.maxContentWidth),
          child: Obx(() {
            if (c.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final failed = c.failedOrders;

            if (failed.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 64, color: AppColors.successBorder),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('No failed orders',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 16)),
                    const SizedBox(height: AppSpacing.xs + 2),
                    const Text('All orders are processing normally',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: c.loadOrders,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                    context.pagePadding, AppSpacing.md, context.pagePadding, 100),
                itemCount: failed.length,
                itemBuilder: (_, i) => _FailedOrderCard(
                  order: failed[i],
                  onTap: () => _openOrder(failed[i]),
                ),
              ),
            );
          }),
        ),
      ),
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

class _FailedOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _FailedOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFlagged = order.isFlagged;
    final color = isFlagged ? AppColors.warning : AppColors.error;

    // Last cancellation/flag action
    final responsibleAction = order.staffActions
        .where((a) => a.action == 'cancelled' || a.action == 'flagged_issue')
        .lastOrNull;

    // Cancellation note
    final cancelAction = order.staffActions
        .where((a) => a.action == 'cancelled')
        .lastOrNull;
    final cancelNote = cancelAction?.note ?? '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    isFlagged ? Icons.flag_rounded : Icons.cancel_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
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
                          const SizedBox(width: 8),
                          _FailTypeBadge(isFlagged: isFlagged),
                        ],
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

            // Flagged issue details
            if (isFlagged && order.flaggedIssue != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.info_outline_rounded,
                color: AppColors.warning,
                label: 'Reason',
                value: order.flaggedIssue!.formattedReason,
              ),
              if (order.flaggedIssue!.note != null &&
                  order.flaggedIssue!.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.notes_rounded,
                  color: AppColors.warning,
                  label: 'Note',
                  value: order.flaggedIssue!.note!,
                ),
              ],
            ],

            // Cancellation note
            if (!isFlagged && cancelNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.notes_rounded,
                color: AppColors.error,
                label: 'Reason',
                value: cancelNote,
              ),
            ],

            // Responsible staff
            if (responsibleAction != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                color: AppColors.neutral,
                label: 'Staff',
                value: responsibleAction.staffName ?? 'Unknown',
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.access_time_rounded,
                color: AppColors.neutral,
                label: 'At',
                value: responsibleAction.formattedTime,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8) : id;
}

class _FailTypeBadge extends StatelessWidget {
  final bool isFlagged;
  const _FailTypeBadge({required this.isFlagged});

  @override
  Widget build(BuildContext context) {
    final color = isFlagged ? AppColors.warning : AppColors.error;
    final label = isFlagged ? 'Flagged' : 'Cancelled';
    final icon = isFlagged ? Icons.flag_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 13),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
