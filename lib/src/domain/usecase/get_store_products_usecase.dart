import '../entity/product_entity.dart';
import '../repo/product_repository.dart';

class GetStoreProductsUseCase {
  final ProductRepository repository;
  GetStoreProductsUseCase(this.repository);

  Future<List<ProductEntity>> execute(String storeId) =>
      repository.getStoreProducts(storeId);
}
