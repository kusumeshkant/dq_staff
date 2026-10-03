import 'package:get/get.dart';

import '../presentation/access/access_page.dart';
import '../presentation/auth/login/login_binding.dart';
import '../presentation/auth/login/login_page.dart';
import '../presentation/auth/register/register_binding.dart';
import '../presentation/auth/register/register_page.dart';
import '../presentation/completed_orders/completed_orders_page.dart';
import '../presentation/exit_validation/exit_validation_binding.dart';
import '../presentation/exit_validation/exit_validation_page.dart';
import '../presentation/failed_orders/failed_orders_page.dart';
import '../presentation/home/home_binding.dart';
import '../presentation/home/home_page.dart';
import '../presentation/invite/invite_code_binding.dart';
import '../presentation/invite/invite_code_page.dart';
import '../presentation/my_orders/my_orders_page.dart';
import '../presentation/orders/orders_binding.dart';
import '../presentation/orders/orders_page.dart';
import '../presentation/scanner/scanner_binding.dart';
import '../presentation/scanner/scanner_page.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.login,    page: () => const LoginPage(),    binding: LoginBinding()),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage(), binding: RegisterBinding()),
    GetPage(name: AppRoutes.invite,   page: () => const InviteCodePage(), binding: InviteCodeBinding()),
    GetPage(name: AppRoutes.home,     page: () => const HomePage(),     binding: HomeBinding(),          middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.orders,   page: () => const OrdersPage(),   binding: OrdersBinding(),        middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.completedOrders, page: () => const CompletedOrdersPage(),                   middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.failedOrders,    page: () => const FailedOrdersPage(),                      middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.myOrders,        page: () => const MyOrdersPage(),                          middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.scanner,  page: () => const ScannerPage(),  binding: ScannerBinding(),       middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.exitValidation, page: () => const ExitValidationPage(), binding: ExitValidationBinding(), middlewares: [AuthMiddleware()]),
    GetPage(name: AppRoutes.access,   page: () => const AccessPage(),                                   middlewares: [AuthMiddleware()]),
  ];
}
