import 'package:dq_staff/design_system/design_system.dart';
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
                'Order #${_shortId(c.order.value.id)}',
              )),
          actions: [
            Obx(() => c.order.value.status != 'completed' &&
                    c.order.value.status != 'cancelled'
                ? IconButton(
                    icon: const Icon(Icons.flag_rounded, color: AppColors.warning),
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

                // ── Completion / Cancellation banner ──────────────────────
                if (o.status == 'completed') ...[
                  _CompletionBanner(order: o),
                  const SizedBox(height: 12),
                ] else if (o.status == 'cancelled') ...[
                  _CancellationBanner(order: o),
                  const SizedBox(height: 12),
                ],

                // ── Order header ──────────────────────────────────────────
                AppGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              o.storeName ?? 'Store',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          DsStatusBadge(status: o.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(o.formattedDate,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          if (o.storeCode != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.infoSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.infoBorder),
                              ),
                              child: Text(o.storeCode!,
                                  style: const TextStyle(
                                      color: AppColors.info,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      if (o.isFlagged) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.errorSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.errorBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_rounded,
                                  color: AppColors.error, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Issue: ${o.flaggedIssue!.formattedReason}'
                                  '${o.flaggedIssue!.note?.isNotEmpty == true ? ' — ${o.flaggedIssue!.note}' : ''}',
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 12),
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

                // ── Status Timeline ───────────────────────────────────────
                _sectionLabel('Order Status'),
                _StatusTimeline(order: o),
                const SizedBox(height: 12),

                // ── Product checklist (when preparing) ───────────────────
                if (o.status == 'preparing') ...[
                  _sectionLabel('Verify Products'),
                  AppGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Obx(() => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
                                            ? AppColors.success
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
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: checked
                                              ? AppColors.success
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: checked
                                                ? AppColors.success
                                                : AppTheme.cardBorder,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: checked
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 14)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                color: checked
                                                    ? AppTheme.textSecondary
                                                    : AppTheme.textPrimary,
                                                fontSize: 14,
                                                decoration: checked
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              item.barcode,
                                              style: const TextStyle(
                                                  color:
                                                      AppTheme.textSecondary,
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            '₹${(item.quantity * item.price).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
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
                  // ── Product list (non-preparing) ─────────────────────
                  _sectionLabel('Products'),
                  AppGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: const [
                              Expanded(
                                child: Text('Item',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4)),
                              ),
                              SizedBox(width: 8),
                              Text('Qty',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(width: 16),
                              Text('Total',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        ...o.items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${item.price.toStringAsFixed(0)} each  ·  ${item.barcode}',
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '×${item.quantity}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '₹${(item.quantity * item.price).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < o.items.length - 1)
                                const Divider(
                                    color: Colors.white12,
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16),
                            ],
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Pricing breakdown ─────────────────────────────────────
                _sectionLabel('Pricing'),
                AppGlassCard(
                  child: Column(
                    children: [
                      _totalRow('Subtotal',
                          '₹${o.total.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      _totalRow('Tax (18%)',
                          '₹${o.tax.toStringAsFixed(2)}'),
                      const Divider(color: Colors.white12, height: 16),
                      _totalRow(
                          'Grand Total',
                          '₹${o.grandTotal.toStringAsFixed(2)}',
                          bold: true),
                    ],
                  ),
                ),

                // ── Staff activity log ────────────────────────────────────
                if (o.staffActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionLabel('Activity Log'),
                  AppGlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: o.staffActions.reversed
                          .map((a) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                                  color:
                                                      AppTheme.textSecondary,
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

        // ── Bottom action button ──────────────────────────────────────────
        bottomNavigationBar: Obx(() {
          final o = c.order.value;
          final label = o.nextStatusLabel;
          if (label == null) return const SizedBox.shrink();

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
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : ElevatedButton(
                      onPressed: canProceed ? c.updateStatus : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canProceed
                            ? _actionButtonColor(o.nextStatus ?? '')
                            : Colors.white12,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_actionButtonIcon(o.nextStatus ?? ''),
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            canProceed
                                ? label
                                : 'Check all items to proceed',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8) : id;

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
                  color: bold
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 15 : 13)),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 15 : 13)),
        ],
      );

  IconData _actionIcon(String action) => switch (action) {
        'started_preparing' => Icons.restaurant_rounded,
        'marked_ready' => Icons.shopping_bag_rounded,
        'completed' => Icons.check_circle_rounded,
        'cancelled' => Icons.cancel_rounded,
        'flagged_issue' => Icons.flag_rounded,
        _ => Icons.info_outline_rounded,
      };

  Color _actionColor(String action) => switch (action) {
        'started_preparing' => AppColors.warning,
        'marked_ready' => AppColors.info,
        'completed' => AppColors.success,
        'cancelled' => AppColors.error,
        'flagged_issue' => AppColors.error,
        _ => AppColors.neutral,
      };

  Color _actionButtonColor(String next) => switch (next) {
        'preparing' => AppColors.warning,
        'ready' => AppColors.info,
        'completed' => AppColors.success,
        _ => AppTheme.primary,
      };

  IconData _actionButtonIcon(String next) => switch (next) {
        'preparing' => Icons.restaurant_rounded,
        'ready' => Icons.shopping_bag_rounded,
        'completed' => Icons.check_circle_rounded,
        _ => Icons.arrow_forward_rounded,
      };
}

// ── Status Timeline ───────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final OrderEntity order;
  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();

    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isLast = i == steps.length - 1;
          return _TimelineStep(step: step, isLast: isLast);
        }).toList(),
      ),
    );
  }

  List<_StepData> _buildSteps() {
    final statuses = ['pending', 'preparing', 'ready', 'completed'];
    final currentIdx = statuses.indexOf(order.status.toLowerCase());
    final isCancelled = order.status.toLowerCase() == 'cancelled';

    // Map actions to their status step
    StaffActionEntity? actionFor(String status) {
      final actionName = switch (status) {
        'preparing' => 'started_preparing',
        'ready' => 'marked_ready',
        'completed' => 'completed',
        'cancelled' => 'cancelled',
        _ => '',
      };
      try {
        return order.staffActions
            .lastWhere((a) => a.action == actionName);
      } catch (_) {
        return null;
      }
    }

    final steps = <_StepData>[];

    // Pending — always first, use order.createdAt
    steps.add(_StepData(
      label: 'Order Placed',
      status: 'pending',
      state: _StepState.done,
      timestamp: order.formattedDate,
      staffName: null,
    ));

    if (isCancelled) {
      final action = actionFor('cancelled');
      steps.add(_StepData(
        label: 'Cancelled',
        status: 'cancelled',
        state: _StepState.cancelled,
        timestamp: action?.formattedTime,
        staffName: action?.staffName,
      ));
      return steps;
    }

    for (int i = 1; i < statuses.length; i++) {
      final s = statuses[i];
      final isDone = i <= currentIdx;
      final isCurrent = i == currentIdx;
      final action = actionFor(s);
      steps.add(_StepData(
        label: _stepLabel(s),
        status: s,
        state: isDone
            ? _StepState.done
            : isCurrent
                ? _StepState.active
                : _StepState.pending,
        timestamp: action?.formattedTime,
        staffName: action?.staffName,
      ));
    }

    return steps;
  }

  String _stepLabel(String status) => switch (status) {
        'preparing' => 'Preparing',
        'ready' => 'Ready for Pickup',
        'completed' => 'Completed',
        _ => status,
      };
}

enum _StepState { done, active, pending, cancelled }

class _StepData {
  final String label;
  final String status;
  final _StepState state;
  final String? timestamp;
  final String? staffName;

  const _StepData({
    required this.label,
    required this.status,
    required this.state,
    this.timestamp,
    this.staffName,
  });
}

class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isLast;
  const _TimelineStep({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = switch (step.state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppTheme.primary,
      _StepState.cancelled => AppColors.error,
      _StepState.pending => Colors.white24,
    };

    final icon = switch (step.state) {
      _StepState.done => Icons.check_circle_rounded,
      _StepState.active => Icons.radio_button_checked_rounded,
      _StepState.cancelled => Icons.cancel_rounded,
      _StepState.pending => Icons.radio_button_unchecked_rounded,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: step.state == _StepState.done
                          ? AppColors.successBorder
                          : Colors.white12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      color: step.state == _StepState.pending
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontWeight: step.state == _StepState.active ||
                              step.state == _StepState.done
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.timestamp!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                  if (step.staffName != null) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          step.staffName!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion Banner ─────────────────────────────────────────────────────────

class _CompletionBanner extends StatelessWidget {
  final OrderEntity order;
  const _CompletionBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final completedAction = order.staffActions
        .where((a) => a.action == 'completed')
        .lastOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Completed',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                if (completedAction?.staffName != null)
                  Text(
                    'by ${completedAction!.staffName}',
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 12),
                  ),
                if (completedAction?.formattedTime != null)
                  Text(
                    completedAction!.formattedTime,
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationBanner extends StatelessWidget {
  final OrderEntity order;
  const _CancellationBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Text('Order Cancelled',
              style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

