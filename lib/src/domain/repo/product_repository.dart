import '../entity/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getStoreProducts(String storeId);
  Future<ProductEntity> createProduct({
    required String storeId,
    required String barcode,
    String? sku,
    required String name,
    String? description,
    required double price,
    required int stock,
  });
  Future<ProductEntity> updateProduct(
    String id, {
    String? sku,
    required String name,
    String? description,
    required double price,
    required int stock,
  });
  Future<bool> deleteProduct(String id);
}
