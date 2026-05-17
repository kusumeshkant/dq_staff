import '../entity/order_entity.dart';
import '../repo/order_repository.dart';

class GetStoreOrdersUseCase {
  final OrderRepository repo;
  GetStoreOrdersUseCase(this.repo);

  Future<List<OrderEntity>> execute(String storeId) => repo.getStoreOrders(storeId);
}
