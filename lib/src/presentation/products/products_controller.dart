import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/product_entity.dart';
import '../../domain/usecase/delete_product_usecase.dart';
import '../../domain/usecase/get_store_products_usecase.dart';
import '../../service_core/auth/session_manager.dart';

class ProductsController extends GetxController {
  final GetStoreProductsUseCase getStoreProductsUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  ProductsController({
    required this.getStoreProductsUseCase,
    required this.deleteProductUseCase,
  });

  final RxList<ProductEntity> products = <ProductEntity>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  Timer? _pollingTimer;

  List<ProductEntity> get filtered {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    searchController.addListener(() => searchQuery.value = searchController.text);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _silentRefresh(),
    );
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> _silentRefresh() async {
    final storeId = Get.find<SessionManager>().storeId;
    if (storeId == null) return;
    try {
      final result = await getStoreProductsUseCase.execute(storeId);
      products.assignAll(result);
    } catch (_) {}
  }

  Future<void> loadProducts() async {
    final storeId = Get.find<SessionManager>().storeId;
    if (storeId == null) return;

    isLoading.value = true;
    try {
      final result = await getStoreProductsUseCase.execute(storeId);
      products.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void upsertProduct(ProductEntity product) {
    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      products[idx] = product;
      products.refresh();
    } else {
      products.insert(0, product);
    }
  }

  Future<void> confirmDelete(ProductEntity product) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A2B3C),
        title: const Text('Delete Product',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${product.name}" from inventory?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await deleteProductUseCase.execute(product.id);
      products.removeWhere((p) => p.id == product.id);
      Get.snackbar('Deleted', '${product.name} removed from inventory.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
