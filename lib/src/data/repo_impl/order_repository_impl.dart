import '../../domain/entity/order_entity.dart';
import '../../domain/repo/order_repository.dart';
import '../datasources/remote/order_remote_ds.dart';
import '../model/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDs ds;
  OrderRepositoryImpl(this.ds);

  @override
  Future<List<OrderEntity>> getStoreOrders(String storeId) async {
    final list = await ds.getStoreOrders(storeId);
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  @override
  Future<OrderEntity?> getOrderById(String orderId) async {
    final json = await ds.getOrderById(orderId);
    if (json == null) return null;
    return OrderModel.fromJson(json);
  }

  @override
  Future<OrderEntity> updateOrderStatus(String orderId, String status) async {
    final json = await ds.updateOrderStatus(orderId, status);
    // Backend returns partial order — reload full order
    final full = await ds.getOrderById(orderId);
    return OrderModel.fromJson(full ?? json);
  }

  @override
  Future<OrderEntity> flagOrderIssue(
      String orderId, String reason, String note) async {
    await ds.flagOrderIssue(orderId, reason, note);
    final full = await ds.getOrderById(orderId);
    return OrderModel.fromJson(full!);
  }
}
