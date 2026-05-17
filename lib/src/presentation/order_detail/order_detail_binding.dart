import 'package:get/get.dart';
import '../../data/datasources/remote/order_remote_ds.dart';
import '../../data/repo_impl/order_repository_impl.dart';
import '../../domain/usecase/flag_order_issue_usecase.dart';
import '../../domain/usecase/update_order_status_usecase.dart';
import 'order_detail_controller.dart';

class OrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    final ds = OrderRemoteDs();
    final repo = OrderRepositoryImpl(ds);
    Get.lazyPut(() => OrderDetailController(
          updateOrderStatusUseCase: UpdateOrderStatusUseCase(repo),
          flagOrderIssueUseCase: FlagOrderIssueUseCase(repo),
        ));
  }
}
