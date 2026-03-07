class OrderItemEntity {
  final String barcode;
  final String name;
  final double price;
  final int quantity;

  const OrderItemEntity({
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class StaffActionEntity {
  final String? staffId;
  final String? staffName;
  final String action;
  final String timestamp;
  final String? note;

  const StaffActionEntity({
    this.staffId,
    this.staffName,
    required this.action,
    required this.timestamp,
    this.note,
  });

  String get formattedAction => switch (action) {
        'started_preparing' => 'Started Preparing',
        'marked_ready'      => 'Marked Ready',
        'completed'         => 'Completed',
        'cancelled'         => 'Cancelled',
        'flagged_issue'     => 'Flagged Issue',
        _                   => action,
      };

  String get formattedTime {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }
}

class FlaggedIssueEntity {
  final String reason;
  final String? note;
  final String? staffName;
  final String timestamp;

  const FlaggedIssueEntity({
    required this.reason,
    this.note,
    this.staffName,
    required this.timestamp,
  });

  String get formattedReason => switch (reason) {
        'wrong_items'       => 'Wrong Items',
        'payment_mismatch'  => 'Payment Mismatch',
        'customer_absent'   => 'Customer Absent',
        _                   => 'Other',
      };
}

class OrderEntity {
  final String id;
  final String? storeName;
  final String? storeId;
  final double total;
  final double tax;
  final double grandTotal;
  final String status;
  final String createdAt;
  final List<OrderItemEntity> items;
  final List<StaffActionEntity> staffActions;
  final FlaggedIssueEntity? flaggedIssue;

  const OrderEntity({
    required this.id,
    this.storeName,
    this.storeId,
    required this.total,
    required this.tax,
    required this.grandTotal,
    required this.status,
    required this.createdAt,
    required this.items,
    this.staffActions = const [],
    this.flaggedIssue,
  });

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  bool get isFlagged => flaggedIssue != null;

  /// Next valid status for this order
  String? get nextStatus => switch (status.toLowerCase()) {
        'pending'   => 'preparing',
        'preparing' => 'ready',
        'ready'     => 'completed',
        _           => null,
      };

  String? get nextStatusLabel => switch (status.toLowerCase()) {
        'pending'   => 'Start Preparing',
        'preparing' => 'Mark Ready',
        'ready'     => 'Complete Order',
        _           => null,
      };
}
