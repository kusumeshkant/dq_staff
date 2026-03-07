import 'package:dq_staff/widgets/app_glass_card.dart';
import 'package:dq_staff/widgets/themed_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../theme/app_theme.dart';
import 'order_detail_controller.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderEntity order;
  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrderDetailController>();

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Obx(() => Text(
                '#${c.order.value.id.substring(c.order.value.id.length > 8 ? c.order.value.id.length - 8 : 0)}',
              )),
          actions: [
            Obx(() => c.order.value.status != 'completed' &&
                    c.order.value.status != 'cancelled'
                ? IconButton(
                    icon: const Icon(Icons.flag_rounded, color: Colors.orange),
                    tooltip: 'Flag Issue',
                    onPressed: c.showFlagDialog,
                  )
                : const SizedBox.shrink()),
          ],
        ),
        body: Obx(() {
          final o = c.order.value;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                AppGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(o.storeName ?? 'Store',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          _StatusBadge(status: o.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(o.formattedDate,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      if (o.isFlagged) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_rounded,
                                  color: Colors.red, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Issue: ${o.flaggedIssue!.formattedReason}'
                                  '${o.flaggedIssue!.note?.isNotEmpty == true ? ' — ${o.flaggedIssue!.note}' : ''}',
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Product checklist (shown when preparing)
                if (o.status == 'preparing') ...[
                  _sectionLabel('Verify Products'),
                  AppGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Progress bar
                        Obx(() => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: c.totalCount > 0
                                            ? c.checkedCount / c.totalCount
                                            : 0,
                                        backgroundColor: Colors.white12,
                                        color: c.allItemsChecked
                                            ? Colors.green
                                            : AppTheme.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${c.checkedCount}/${c.totalCount}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(color: Colors.white12, height: 1),
                        ...o.items.map((item) => Obx(() {
                              final checked =
                                  c.checkedItems[item.barcode] ?? false;
                              return InkWell(
                                onTap: () => c.toggleItem(item.barcode),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: checked
                                              ? Colors.green
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: checked
                                                ? Colors.green
                                                : AppTheme.cardBorder,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: checked
                                            ? const Icon(Icons.check_rounded,
                                                color: Colors.white, size: 14)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            color: checked
                                                ? AppTheme.textSecondary
                                                : AppTheme.textPrimary,
                                            fontSize: 14,
                                            decoration: checked
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Regular item list (non-preparing)
                  _sectionLabel('Items'),
                  AppGlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: o.items
                          .map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text(item.name,
                                            style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 14))),
                                    Text(
                                      '${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Order total
                AppGlassCard(
                  child: Column(
                    children: [
                      _totalRow('Subtotal', '₹${o.total.toStringAsFixed(0)}'),
                      const SizedBox(height: 4),
                      _totalRow('Tax (18%)', '₹${o.tax.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      _totalRow('Total', '₹${o.grandTotal.toStringAsFixed(0)}',
                          bold: true),
                    ],
                  ),
                ),

                // Staff action history
                if (o.staffActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionLabel('Activity'),
                  AppGlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: o.staffActions.reversed
                          .map((a) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(_actionIcon(a.action),
                                        color: _actionColor(a.action),
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${a.formattedAction}${a.staffName != null ? ' by ${a.staffName}' : ''}',
                                            style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 13),
                                          ),
                                          if (a.note?.isNotEmpty == true)
                                            Text(a.note!,
                                                style: const TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontSize: 11)),
                                          Text(a.formattedTime,
                                              style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        // Bottom action button
        bottomNavigationBar: Obx(() {
          final o = c.order.value;
          final label = o.nextStatusLabel;
          if (label == null) return const SizedBox.shrink();

          // Disable "Mark Ready" until all items checked
          final isReady = o.status == 'preparing';
          final canProceed = !isReady || c.allItemsChecked;

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1B2A),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: c.isUpdating.value
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary))
                  : ElevatedButton(
                      onPressed: canProceed ? c.updateStatus : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canProceed
                            ? AppTheme.primary
                            : Colors.white12,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        canProceed
                            ? label
                            : 'Check all items to proceed',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _totalRow(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color:
                      bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
        ],
      );

  IconData _actionIcon(String action) => switch (action) {
        'started_preparing' => Icons.restaurant_rounded,
        'marked_ready'      => Icons.shopping_bag_rounded,
        'completed'         => Icons.check_circle_rounded,
        'cancelled'         => Icons.cancel_rounded,
        'flagged_issue'     => Icons.flag_rounded,
        _                   => Icons.info_outline_rounded,
      };

  Color _actionColor(String action) => switch (action) {
        'started_preparing' => Colors.orange,
        'marked_ready'      => Colors.blue,
        'completed'         => Colors.green,
        'cancelled'         => Colors.red,
        'flagged_issue'     => Colors.red,
        _                   => Colors.grey,
      };
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status.toLowerCase()) {
      'pending'   => (Colors.grey.shade500, 'Pending'),
      'preparing' => (Colors.orange.shade600, 'Preparing'),
      'ready'     => (Colors.blue.shade500, 'Ready'),
      'completed' => (Colors.green.shade600, 'Completed'),
      'cancelled' => (Colors.red.shade600, 'Cancelled'),
      _           => (Colors.orange.shade400, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
