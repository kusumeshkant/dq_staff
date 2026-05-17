import 'package:get/get.dart';
import '../../data/datasources/remote/order_remote_ds.dart';
import '../../data/datasources/remote/permission_remote_ds.dart';
import '../../data/datasources/remote/product_remote_ds.dart';
import '../../data/repo_impl/order_repository_impl.dart';
import '../../data/repo_impl/product_repository_impl.dart';
import '../../domain/usecase/delete_product_usecase.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import '../../domain/usecase/get_store_orders_usecase.dart';
import '../../domain/usecase/get_store_products_usecase.dart';
import '../../service_core/permission/permission_service.dart';
import '../access/access_controller.dart';
import '../orders/orders_controller.dart';
import '../products/products_controller.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());

    final permDs = PermissionRemoteDs();

    // Register PermissionService and trigger load immediately.
    final permService = Get.put(PermissionService(permDs));
    permService.load();

    Get.lazyPut(() => AccessController(permDs));

    final orderRepo = OrderRepositoryImpl(OrderRemoteDs());
    Get.lazyPut(() => OrdersController(
          getStoreOrdersUseCase: GetStoreOrdersUseCase(orderRepo),
          getOrderByIdUseCase: GetOrderByIdUseCase(orderRepo),
        ));

    final productRepo = ProductRepositoryImpl(ProductRemoteDs());
    Get.lazyPut(() => ProductsController(
          getStoreProductsUseCase: GetStoreProductsUseCase(productRepo),
          deleteProductUseCase: DeleteProductUseCase(productRepo),
        ));
  }
}
