import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/product_entity.dart';
import '../../domain/usecase/create_product_usecase.dart';
import '../../domain/usecase/update_product_usecase.dart';
import '../../service_core/auth/session_manager.dart';
import '../../service_core/permission/permission_service.dart';

class AddEditProductController extends GetxController {
  final CreateProductUseCase createProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final ProductEntity? existing;

  AddEditProductController({
    required this.createProductUseCase,
    required this.updateProductUseCase,
    this.existing,
  });

  final isSaving = false.obs;

  late final TextEditingController barcodeController;
  late final TextEditingController skuController;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;

  bool get isEditing => existing != null;

  bool get isStaff =>
      !(Get.find<SessionManager>().currentUser.value?.isAdmin ?? false);

  @override
  void onInit() {
    super.onInit();
    barcodeController = TextEditingController(text: existing?.barcode ?? '');
    skuController = TextEditingController(text: existing?.sku ?? '');
    nameController = TextEditingController(text: existing?.name ?? '');
    descriptionController =
        TextEditingController(text: existing?.description ?? '');
    priceController = TextEditingController(
        text: existing != null ? existing!.price.toStringAsFixed(2) : '');
    stockController = TextEditingController(
        text: existing != null ? existing!.stock.toString() : '');
  }

  @override
  void onClose() {
    barcodeController.dispose();
    skuController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.onClose();
  }

  void fillBarcode(String barcode) {
    barcodeController.text = barcode;
  }

  Future<void> save() async {
    final barcode = barcodeController.text.trim();
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final stockText = stockController.text.trim();

    // Permission pre-flight — backend will also reject, but fail fast with a clear message.
    try {
      final ps = Get.find<PermissionService>();
      if (!isEditing && !ps.canAddProduct.value) {
        Get.snackbar('No Permission',
            'You do not have permission to add products. Request access in the Access tab.',
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4));
        return;
      }
      if (isEditing && !ps.canEditProductInfo.value) {
        Get.snackbar('No Permission',
            'You do not have permission to edit products. Request access in the Access tab.',
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4));
        return;
      }
    } catch (_) {
      // PermissionService not loaded yet — let backend decide.
    }

    if (!isEditing && barcode.isEmpty) {
      Get.snackbar('Missing', 'Barcode is required.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (name.isEmpty) {
      Get.snackbar('Missing', 'Product name is required.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Staff users don't set price/stock — admin will configure them later.
    double price = 0;
    int stock = 0;
    if (!isStaff) {
      final parsedPrice = double.tryParse(priceText);
      if (parsedPrice == null || parsedPrice < 0) {
        Get.snackbar('Invalid', 'Enter a valid price.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      price = parsedPrice;
      final parsedStock = int.tryParse(stockText);
      if (parsedStock == null || parsedStock < 0) {
        Get.snackbar('Invalid', 'Enter a valid stock quantity.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      stock = parsedStock;
    }

    final sku = skuController.text.trim().isEmpty ? null : skuController.text.trim();
    final description = descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim();

    isSaving.value = true;
    try {
      ProductEntity result;
      if (isEditing) {
        result = await updateProductUseCase.execute(
          existing!.id,
          sku: sku,
          name: name,
          description: description,
          price: price,
          stock: stock,
        );
      } else {
        final storeId = Get.find<SessionManager>().storeId!;
        result = await createProductUseCase.execute(
          storeId: storeId,
          barcode: barcode,
          sku: sku,
          name: name,
          description: description,
          price: price,
          stock: stock,
        );
      }
      Get.back(result: result);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }
}
