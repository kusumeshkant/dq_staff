import '../entity/order_entity.dart';
import '../repo/order_repository.dart';

class FlagOrderIssueUseCase {
  final OrderRepository repo;
  FlagOrderIssueUseCase(this.repo);

  Future<OrderEntity> execute(String orderId, String reason, String note) =>
      repo.flagOrderIssue(orderId, reason, note);
}
