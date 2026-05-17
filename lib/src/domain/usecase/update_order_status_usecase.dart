import '../entity/order_entity.dart';
import '../repo/order_repository.dart';

class UpdateOrderStatusUseCase {
  final OrderRepository repo;
  UpdateOrderStatusUseCase(this.repo);

  Future<OrderEntity> execute(String orderId, String status) =>
      repo.updateOrderStatus(orderId, status);
}
