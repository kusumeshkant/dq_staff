import '../repo/product_repository.dart';

class DeleteProductUseCase {
  final ProductRepository repository;
  DeleteProductUseCase(this.repository);

  Future<bool> execute(String id) => repository.deleteProduct(id);
}
