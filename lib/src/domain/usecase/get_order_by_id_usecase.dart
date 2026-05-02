import '../entity/order_entity.dart';
import '../repo/order_repository.dart';

class GetOrderByIdUseCase {
  final OrderRepository repo;
  GetOrderByIdUseCase(this.repo);

  Future<OrderEntity?> execute(String orderId) => repo.getOrderById(orderId);
}
