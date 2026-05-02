import 'package:get/get.dart';
import '../../data/datasources/remote/order_remote_ds.dart';
import '../../data/repo_impl/order_repository_impl.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import '../../domain/usecase/get_store_orders_usecase.dart';
import 'orders_controller.dart';

class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    final ds = OrderRemoteDs();
    final repo = OrderRepositoryImpl(ds);
    Get.lazyPut(() => OrdersController(
          getStoreOrdersUseCase: GetStoreOrdersUseCase(repo),
          getOrderByIdUseCase: GetOrderByIdUseCase(repo),
        ));
  }
}
