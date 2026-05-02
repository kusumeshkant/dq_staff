class StoreEntity {
  final String id;
  final String name;
  final String? address;
  final String? storeCode;

  const StoreEntity({
    required this.id,
    required this.name,
    this.address,
    this.storeCode,
  });
}
