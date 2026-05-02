class ProductEntity {
  final String id;
  final String storeId;
  final String barcode;
  final String? sku;
  final String name;
  final String? description;
  final double price;
  final int stock;

  const ProductEntity({
    required this.id,
    required this.storeId,
    required this.barcode,
    this.sku,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
  });
}
