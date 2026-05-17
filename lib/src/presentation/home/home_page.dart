import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/src/utils/responsive/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../service_core/permission/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../../widgets/themed_background.dart';
import '../access/access_page.dart';
import '../my_orders/my_orders_page.dart';
import '../orders/orders_page.dart';
import '../products/products_page.dart';
import '../exit_validation/exit_validation_page.dart';
import '../exit_validation/exit_validation_binding.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    ExitValidationBinding().dependencies();

    return ThemedBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          return Obx(() {
            final index = c.currentIndex.value;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                children: [
                  // ── NavigationRail (tablet / desktop) ──────────────
                  if (isWide) ...[
                    NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: c.setIndex,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: AppTheme.background,
                      selectedIconTheme: const IconThemeData(
                          color: AppTheme.primary, size: 22),
                      unselectedIconTheme: const IconThemeData(
                          color: AppTheme.textSecondary, size: 22),
                      selectedLabelTextStyle: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      unselectedLabelTextStyle: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                      destinations: [
                        const NavigationRailDestination(
                          icon: Icon(Icons.receipt_long_outlined),
                          selectedIcon: Icon(Icons.receipt_long_rounded),
                          label: Text('Orders'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2_rounded),
                          label: Text('Inventory'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: Text('My Orders'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.exit_to_app_outlined),
                          selectedIcon: Icon(Icons.exit_to_app_rounded),
                          label: Text('Validate'),
                        ),
                        NavigationRailDestination(
                          icon: _AccessIcon(selected: false),
                          selectedIcon: _AccessIcon(selected: true),
                          label: const Text('Access'),
                        ),
                      ],
                    ),
                    const VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: Color(0x33FFFFFF),
                    ),
                  ],

                  // ── Main content ────────────────────────────────────
                  Expanded(
                    child: IndexedStack(
                      index: index,
                      children: const [
                        OrdersPage(),
                        ProductsPage(),
                        MyOrdersPage(),
                        ExitValidationPage(),
                        AccessPage(),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Bottom nav (mobile only) ────────────────────────────
              bottomNavigationBar: isWide
                  ? null
                  : BottomNavigationBar(
                      currentIndex: index,
                      onTap: c.setIndex,
                      backgroundColor: AppTheme.background,
                      selectedItemColor: AppTheme.primary,
                      unselectedItemColor: AppTheme.textSecondary,
                      type: BottomNavigationBarType.fixed,
                      selectedLabelStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      unselectedLabelStyle:
                          const TextStyle(fontSize: 11),
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.receipt_long_outlined),
                          activeIcon: Icon(Icons.receipt_long_rounded),
                          label: 'Orders',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.inventory_2_outlined),
                          activeIcon: Icon(Icons.inventory_2_rounded),
                          label: 'Inventory',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline_rounded),
                          activeIcon: Icon(Icons.person_rounded),
                          label: 'My Orders',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.exit_to_app_outlined),
                          activeIcon: Icon(Icons.exit_to_app_rounded),
                          label: 'Validate Exit',
                        ),
                        BottomNavigationBarItem(
                          icon: _AccessIcon(selected: false),
                          activeIcon: _AccessIcon(selected: true),
                          label: 'Access',
                        ),
                      ],
                    ),
            );
          });
        },
      ),
    );
  }
}

// ── Access tab icon with optional permission dot ───────────────────────────────

class _AccessIcon extends StatelessWidget {
  final bool selected;
  const _AccessIcon({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(selected
            ? Icons.verified_user_rounded
            : Icons.verified_user_outlined),
        Obx(() {
          final ps = Get.find<PermissionService>();
          final anyGranted = ps.canDiscount.value ||
              ps.canEditProductInfo.value ||
              ps.canAddProduct.value ||
              ps.canDeleteProduct.value;
          if (!anyGranted) return const SizedBox.shrink();
          return Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ],
    );
  }
}
