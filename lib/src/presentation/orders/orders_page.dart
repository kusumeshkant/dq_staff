import 'package:dq_staff/widgets/app_glass_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../service_core/auth/session_manager.dart';
import '../../service_core/networks/graphql_client_provider.dart';
import '../../service_core/permission/permission_service.dart';
import '../../theme/app_theme.dart';
import '../access/access_controller.dart';
import '../completed_orders/completed_orders_page.dart';
import '../failed_orders/failed_orders_page.dart';
import '../home/home_controller.dart';
import '../products/products_controller.dart';
import '../scanner/scanner_page.dart';
import '../scanner/scanner_binding.dart';
import 'orders_controller.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrdersController>();
    final session = Get.find<SessionManager>();

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Obx(() => Text(
                session.currentUser.value?.name != null
                    ? 'Hello, ${session.currentUser.value!.name}'
                    : 'Orders',
              )),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign out',
              onPressed: () async {
                // Clean up controllers before navigation
                try { Get.delete<OrdersController>(force: true); } catch (_) {}
                try { Get.delete<ProductsController>(force: true); } catch (_) {}
                try { Get.delete<AccessController>(force: true); } catch (_) {}
                try { Get.delete<PermissionService>(force: true); } catch (_) {}
                try { Get.delete<HomeController>(force: true); } catch (_) {}
                GraphQLClientProvider.reset();
                await FirebaseAuth.instance.signOut();
                // expireSession clears cache + navigates to login
                await Get.find<SessionManager>().expireSession();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          backgroundColor: AppTheme.primary,
          onPressed: () => Get.to(
            () => const ScannerPage(),
            binding: ScannerBinding(),
          )?.then((_) => c.loadOrders()),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        ),
        body: Column(
          children: [
            // Staff detail card
            _StaffDetailCard(session: session),

            // Stats row
            Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Active',
                        value: c.activeCount,
                        color: AppTheme.primary,
                        icon: Icons.receipt_long_rounded,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Failed',
                        value: c.failedCount,
                        color: Colors.red,
                        icon: Icons.cancel_rounded,
                        onTap: () => Get.to(() => const FailedOrdersPage()),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'My Done',
                        value: c.myCompletedCount,
                        color: Colors.green,
                        icon: Icons.check_circle_rounded,
                        onTap: () =>
                            Get.find<HomeController>().goToTab(2),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Completed',
                        value: c.completedCount,
                        color: Colors.teal,
                        icon: Icons.done_all_rounded,
                        onTap: () => Get.to(() => const CompletedOrdersPage()),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c.searchController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter Order ID...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.textSecondary),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onSubmitted: (_) => c.searchByOrderId(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => c.isSearching.value
                      ? const SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primary, strokeWidth: 2))))
                      : IconButton(
                          onPressed: c.searchByOrderId,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded,
                              color: AppTheme.primary),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Orders list
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary));
                }
                if (c.activeOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('No active orders',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text('Completed & cancelled orders are filtered out',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.loadOrders,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: c.activeOrders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: c.activeOrders[i],
                      onTap: () => c.openOrder(c.activeOrders[i]),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppGlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status indicator dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _statusColor(order.status),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${order.id.substring(order.id.length > 8 ? order.id.length - 8 : 0)}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (order.isFlagged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded,
                                  color: Colors.red, size: 11),
                              SizedBox(width: 3),
                              Text('Issue',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (order.storeName != null || order.storeCode != null)
                    Row(
                      children: [
                        if (order.storeCode != null)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              order.storeCode!,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (order.storeName != null)
                          Text(
                            order.storeName!,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}  ·  ₹${order.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.formattedDate,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'pending'   => Colors.grey.shade400,
        'preparing' => Colors.orange.shade400,
        'ready'     => Colors.blue.shade400,
        'completed' => Colors.green.shade400,
        'cancelled' => Colors.red.shade400,
        _           => Colors.orange.shade300,
      };
}

// ── Staff Detail Card ─────────────────────────────────────────────────────────

class _StaffDetailCard extends StatelessWidget {
  final SessionManager session;
  const _StaffDetailCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = session.currentUser.value;
      final store = session.currentStore.value;
      if (user == null) return const SizedBox.shrink();

      final initials = _initials(user.name);
      final isAdmin = user.isAdmin;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: AppGlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Staff info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name ?? 'Staff',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isAdmin ? Colors.purple : AppTheme.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  (isAdmin ? Colors.purple : AppTheme.primary)
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : 'Staff',
                            style: TextStyle(
                              color:
                                  isAdmin ? Colors.purple : AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Store info
                    Row(
                      children: [
                        const Icon(Icons.store_rounded,
                            color: AppTheme.textSecondary, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store?.name ?? 'Loading store...',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (store?.storeCode != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.teal.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              store!.storeCode!,
                              style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (store?.address != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppTheme.textSecondary, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store!.address!,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

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
