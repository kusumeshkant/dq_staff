import '../entity/product_entity.dart';
import '../repo/product_repository.dart';

class UpdateProductUseCase {
  final ProductRepository repository;
  UpdateProductUseCase(this.repository);

  Future<ProductEntity> execute(
    String id, {
    String? sku,
    required String name,
    String? description,
    required double price,
    required int stock,
  }) =>
      repository.updateProduct(
        id,
        sku: sku,
        name: name,
        description: description,
        price: price,
        stock: stock,
      );
}
