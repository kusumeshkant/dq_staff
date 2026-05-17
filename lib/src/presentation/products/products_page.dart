import 'package:dq_staff/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entity/product_entity.dart';
import '../../service_core/permission/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../../widgets/app_glass_card.dart';
import 'add_edit_product_binding.dart';
import 'add_edit_product_page.dart';
import 'products_controller.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductsController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: c.loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final ps = Get.find<PermissionService>();
        if (!ps.canAddProduct.value) return const SizedBox.shrink();
        return FloatingActionButton(
          heroTag: null,
          backgroundColor: AppTheme.primary,
          onPressed: () => _openAddProduct(c),
          child: const Icon(Icons.add_rounded, color: Colors.white),
        );
      }),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: c.searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by name, barcode or SKU...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary));
              }
              final list = c.filtered;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 56,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        c.searchQuery.value.isEmpty
                            ? 'No products yet\nTap + to add one'
                            : 'No results found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: c.loadProducts,
                color: AppTheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final ps = Get.find<PermissionService>();
                    return Obx(() => _ProductCard(
                      product: list[i],
                      canEdit: ps.canEditProductInfo.value,
                      canDelete: ps.canDeleteProduct.value,
                      onEdit: () => _openEditProduct(c, list[i]),
                      onDelete: () => c.confirmDelete(list[i]),
                    ));
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openAddProduct(ProductsController c) async {
    final result = await Get.to<ProductEntity>(
      () => const AddEditProductPage(),
      binding: AddEditProductBinding(),
    );
    if (result != null) {
      c.upsertProduct(result);
      Get.snackbar('Added', '${result.name} added to inventory.',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _openEditProduct(ProductsController c, ProductEntity product) async {
    final result = await Get.to<ProductEntity>(
      () => const AddEditProductPage(),
      binding: AddEditProductBinding(existing: product),
    );
    if (result != null) {
      c.upsertProduct(result);
      Get.snackbar('Updated', '${result.name} updated.',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock <= 5;

    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Stock indicator
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: product.stock == 0
                  ? AppColors.error
                  : isLowStock
                      ? AppColors.warning
                      : AppColors.success,
              shape: BoxShape.circle,
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.sku != null) ...[
                      _chip(product.sku!, AppTheme.primary),
                      const SizedBox(width: 6),
                    ],
                    _chip(product.barcode, Colors.white24),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                          color: isLowStock ? AppColors.warning : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal),
                    ),
                    if (product.stock == 0) ...[
                      const SizedBox(width: 6),
                      const Text('OUT',
                          style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Edit / Delete actions — only shown if permitted
          if (canEdit || canDelete)
            Column(
              children: [
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.primary, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                if (canDelete)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color == Colors.white24
                    ? AppTheme.textSecondary
                    : color,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      );
}
