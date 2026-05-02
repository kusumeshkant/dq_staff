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
      child: Obx(() => Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(
              index: c.currentIndex.value,
              children: const [
                OrdersPage(),
                ProductsPage(),
                MyOrdersPage(),
                ExitValidationPage(),
                AccessPage(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: c.currentIndex.value,
              onTap: c.setIndex,
              backgroundColor: const Color(0xFF0D1B2A),
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
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
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.verified_user_outlined),
                      Obx(() {
                        final ps = Get.find<PermissionService>();
                        final anyGranted = ps.canDiscount.value ||
                            ps.canEditProductInfo.value ||
                            ps.canAddProduct.value ||
                            ps.canDeleteProduct.value;
                        if (!anyGranted) return const SizedBox.shrink();
                        return Positioned(
                          top: -2, right: -2,
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  activeIcon: const Icon(Icons.verified_user_rounded),
                  label: 'Access',
                ),
              ],
            ),
          )),
    );
  }
}
