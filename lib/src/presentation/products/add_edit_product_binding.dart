import 'package:get/get.dart';
import '../../data/datasources/remote/product_remote_ds.dart';
import '../../data/repo_impl/product_repository_impl.dart';
import '../../domain/entity/product_entity.dart';
import '../../domain/usecase/create_product_usecase.dart';
import '../../domain/usecase/update_product_usecase.dart';
import 'add_edit_product_controller.dart';

class AddEditProductBinding extends Bindings {
  final ProductEntity? existing;
  AddEditProductBinding({this.existing});

  @override
  void dependencies() {
    final repo = ProductRepositoryImpl(ProductRemoteDs());
    Get.lazyPut(() => AddEditProductController(
          createProductUseCase: CreateProductUseCase(repo),
          updateProductUseCase: UpdateProductUseCase(repo),
          existing: existing,
        ));
  }
}
