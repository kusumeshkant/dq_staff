import 'package:get/get.dart';
import '../../data/datasources/remote/product_remote_ds.dart';
import '../../data/repo_impl/product_repository_impl.dart';
import '../../domain/usecase/delete_product_usecase.dart';
import '../../domain/usecase/get_store_products_usecase.dart';
import 'products_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    final repo = ProductRepositoryImpl(ProductRemoteDs());
    Get.lazyPut(() => ProductsController(
          getStoreProductsUseCase: GetStoreProductsUseCase(repo),
          deleteProductUseCase: DeleteProductUseCase(repo),
        ));
  }
}
