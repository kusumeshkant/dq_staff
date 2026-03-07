import '../../domain/entity/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.barcode,
    required super.name,
    required super.price,
    required super.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        barcode: json['barcode'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
      );
}

class StaffActionModel extends StaffActionEntity {
  const StaffActionModel({
    super.staffId,
    super.staffName,
    required super.action,
    required super.timestamp,
    super.note,
  });

  factory StaffActionModel.fromJson(Map<String, dynamic> json) =>
      StaffActionModel(
        staffId: json['staffId'] as String?,
        staffName: json['staffName'] as String?,
        action: json['action'] as String,
        timestamp: json['timestamp'] as String,
        note: json['note'] as String?,
      );
}

class FlaggedIssueModel extends FlaggedIssueEntity {
  const FlaggedIssueModel({
    required super.reason,
    super.note,
    super.staffName,
    required super.timestamp,
  });

  factory FlaggedIssueModel.fromJson(Map<String, dynamic> json) =>
      FlaggedIssueModel(
        reason: json['reason'] as String,
        note: json['note'] as String?,
        staffName: json['staffName'] as String?,
        timestamp: json['timestamp'] as String,
      );
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    super.storeName,
    super.storeId,
    required super.total,
    required super.tax,
    required super.grandTotal,
    required super.status,
    required super.createdAt,
    required super.items,
    super.staffActions,
    super.flaggedIssue,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        storeName: json['storeName'] as String?,
        storeId: json['storeId'] as String?,
        total: (json['total'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        grandTotal: (json['grandTotal'] as num).toDouble(),
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        staffActions: ((json['staffActions'] as List<dynamic>?) ?? [])
            .map((e) => StaffActionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        flaggedIssue: json['flaggedIssue'] != null
            ? FlaggedIssueModel.fromJson(
                json['flaggedIssue'] as Map<String, dynamic>)
            : null,
      );

  OrderModel copyWithStatus(String newStatus,
          List<StaffActionEntity> newActions) =>
      OrderModel(
        id: id,
        storeName: storeName,
        storeId: storeId,
        total: total,
        tax: tax,
        grandTotal: grandTotal,
        status: newStatus,
        createdAt: createdAt,
        items: items,
        staffActions: newActions,
        flaggedIssue: flaggedIssue,
      );
}
