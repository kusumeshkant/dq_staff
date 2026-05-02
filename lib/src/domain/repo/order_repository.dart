import '../entity/order_entity.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getStoreOrders(String storeId);
  Future<OrderEntity?> getOrderById(String orderId);
  Future<OrderEntity> updateOrderStatus(String orderId, String status);
  Future<OrderEntity> flagOrderIssue(String orderId, String reason, String note);
}
