import 'package:dq_staff/widgets/app_glass_card.dart';
import 'package:dq_staff/widgets/themed_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/order_entity.dart';
import '../../service_core/auth/session_manager.dart';
import '../../service_core/networks/graphql_client_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login/login_binding.dart';
import '../auth/login/login_page.dart';
import '../scanner/scanner_page.dart';
import '../scanner/scanner_binding.dart';
import 'orders_controller.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrdersController>();
    final session = Get.find<SessionManager>();

    return ThemedBackground(
      child: Scaffold(
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
                Get.find<SessionManager>().clearUser();
                GraphQLClientProvider.reset();
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => const LoginPage(), binding: LoginBinding());
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primary,
          onPressed: () => Get.to(
            () => const ScannerPage(),
            binding: ScannerBinding(),
          )?.then((_) => c.loadOrders()),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        ),
        body: Column(
          children: [
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
                if (c.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('No orders yet',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.loadOrders,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: c.orders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: c.orders[i],
                      onTap: () => c.openOrder(c.orders[i]),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

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
