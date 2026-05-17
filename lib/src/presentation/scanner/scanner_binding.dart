import 'package:get/get.dart';
import '../../data/datasources/remote/order_remote_ds.dart';
import '../../data/repo_impl/order_repository_impl.dart';
import '../../domain/usecase/get_order_by_id_usecase.dart';
import 'scanner_controller.dart';

class ScannerBinding extends Bindings {
  @override
  void dependencies() {
    final ds = OrderRemoteDs();
    final repo = OrderRepositoryImpl(ds);
    Get.lazyPut(() => ScannerController(
          getOrderByIdUseCase: GetOrderByIdUseCase(repo),
        ));
  }
}
