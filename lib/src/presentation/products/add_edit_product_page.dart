import 'package:dq_staff/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import 'add_edit_product_controller.dart';

class AddEditProductPage extends StatelessWidget {
  const AddEditProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddEditProductController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(c.isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          Obx(() => c.isSaving.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: c.save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barcode field (only for new products)
            if (!c.isEditing) ...[
              _label('Barcode *'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c.barcodeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 8901234567890',
                        prefixIcon: Icon(Icons.barcode_reader,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ScanButton(onScanned: c.fillBarcode),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Name
            _label('Product Name *'),
            TextField(
              controller: c.nameController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Slim Fit Jeans',
                prefixIcon:
                    Icon(Icons.label_outline, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // SKU
            _label('SKU (optional)'),
            TextField(
              controller: c.skuController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. ZUD-JNS-32',
                prefixIcon:
                    Icon(Icons.tag_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Price & Stock — admin only. Staff see an informational note.
            if (c.isStaff) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite04,
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                  border: Border.all(color: AppColors.glassWhite20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.textSecondary, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Price and stock are set by your admin after review.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Price (₹) *'),
                        TextField(
                          controller: c.priceController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.currency_rupee_rounded,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Stock *'),
                        TextField(
                          controller: c.stockController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.inventory_2_outlined,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Description
            _label('Description (optional)'),
            TextField(
              controller: c.descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Brief product description...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonLg,
              child: Obx(() => ElevatedButton(
                    onPressed: c.isSaving.value ? null : c.save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    child: c.isSaving.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            c.isEditing ? 'Update Product' : 'Add to Inventory',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
        child: Text(text, style: AppTypography.labelLarge),
      );
}

// Inline scanner button — opens camera, pops barcode back
class _ScanButton extends StatelessWidget {
  final void Function(String barcode) onScanned;
  const _ScanButton({required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final barcode = await Get.to<String>(() => const _BarcodeScanPage());
        if (barcode != null && barcode.isNotEmpty) {
          onScanned(barcode);
        }
      },
      child: Container(
        width: AppSizes.touchTarget,
        height: AppSizes.touchTarget,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.qr_code_scanner_rounded,
            color: AppColors.primary, size: AppSizes.iconMd - 2),
      ),
    );
  }
}

class _BarcodeScanPage extends StatefulWidget {
  const _BarcodeScanPage();

  @override
  State<_BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<_BarcodeScanPage> {
  final MobileScannerController _cam = MobileScannerController();
  bool _popped = false;

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _cam.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cam,
            onDetect: (capture) {
              if (_popped) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null && code.isNotEmpty) {
                _popped = true;
                Get.back(result: code);
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at the product barcode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
