import 'package:dq_staff/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../service_core/permission/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../../widgets/app_glass_card.dart';
import 'access_controller.dart';

class AccessPage extends StatelessWidget {
  const AccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AccessController>();
    final ps = Get.find<PermissionService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Access & Discounts'),
        actions: [
          Obx(() => ps.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary)))
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: ps.load,
                  tooltip: 'Refresh permissions',
                )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ps.load();
          await c.loadMyRequests();
        },
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            // ── My Permissions ───────────────────────────────────────────────
            _sectionTitle('My Permissions'),
            const SizedBox(height: 8),
            Obx(() => AppGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PermRow('Discount Codes',
                      Icons.percent_rounded,
                      ps.canDiscount.value,
                      subtitle: ps.canDiscount.value
                          ? 'Up to ${ps.maxDiscountPercent.value.toStringAsFixed(0)}%'
                          : null),
                  const SizedBox(height: 10),
                  _PermRow('Edit Product Info',
                      Icons.edit_rounded,
                      ps.canEditProductInfo.value),
                  const SizedBox(height: 10),
                  _PermRow('Add Products',
                      Icons.add_box_rounded,
                      ps.canAddProduct.value),
                  const SizedBox(height: 10),
                  _PermRow('Delete Products',
                      Icons.delete_forever_rounded,
                      ps.canDeleteProduct.value),
                  const SizedBox(height: 10),
                  _PermRow('Bulk Upload',
                      Icons.upload_file_rounded,
                      ps.canBulkUploadProducts.value),
                ],
              ),
            )),

            // ── Discount Code Generator ───────────────────────────────────────
            Obx(() => ps.canDiscount.value
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _sectionTitle('Generate Discount Code'),
                      const SizedBox(height: 8),
                      AppGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Obx(() {
                          final code = c.generatedCode.value;
                          if (code != null) {
                            return _GeneratedCodeCard(
                              code: code['code'] as String,
                              percent: (code['discountPercent'] as num).toDouble(),
                              expiresAt: code['expiresAt'] as String,
                              onCopy: c.copyCode,
                              onDismiss: c.clearGeneratedCode,
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate a one-time code for a customer. '
                                'The code expires in 15 minutes.',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: c.discountPctCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                                      ],
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Discount % (max ${ps.maxDiscountPercent.value.toStringAsFixed(0)}%)',
                                        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                        prefixIcon: const Icon(Icons.percent_rounded,
                                            color: AppTheme.textSecondary, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Colors.white24)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Colors.white24)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Obx(() => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                    ),
                                    onPressed: c.isGenerating.value ? null : c.generateCode,
                                    child: c.isGenerating.value
                                        ? const SizedBox(width: 18, height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white))
                                        : const Text('Generate',
                                            style: TextStyle(fontWeight: FontWeight.bold)),
                                  )),
                                ],
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  )
                : const SizedBox.shrink()),

            // ── Request Access ────────────────────────────────────────────────
            const SizedBox(height: 20),
            _sectionTitle('Request Access'),
            const SizedBox(height: 8),
            AppGlassCard(
              padding: const EdgeInsets.all(16),
              child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request type',
                      style: TextStyle(color: AppTheme.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: c.selectedRequestType.value,
                    dropdownColor: const Color(0xFF1A2B3C),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'discount',     child: Text('Discount Codes')),
                      DropdownMenuItem(value: 'product_edit', child: Text('Product Edit')),
                      DropdownMenuItem(value: 'bulk_upload',  child: Text('Bulk Upload')),
                    ],
                    onChanged: (v) {
                      c.selectedRequestType.value = v ?? 'discount';
                      c.selectedProductPerms.clear();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Discount-specific: max % field
                  if (c.selectedRequestType.value == 'discount') ...[
                    const Text('Requested max discount %',
                        style: TextStyle(color: AppTheme.textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: c.discountReqPctCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. 15',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.percent_rounded,
                            color: AppTheme.textSecondary, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white24)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Product edit: checkboxes
                  if (c.selectedRequestType.value == 'product_edit') ...[
                    const Text('Permissions to request',
                        style: TextStyle(color: AppTheme.textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...['canEditProductInfo', 'canAddProduct', 'canDeleteProduct'].map((perm) {
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: c.selectedProductPerms.contains(perm),
                        title: Text(_permLabel(perm),
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        checkColor: Colors.white,
                        activeColor: AppTheme.primary,
                        onChanged: (_) => c.toggleProductPerm(perm),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  const Text('Reason',
                      style: TextStyle(color: AppTheme.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c.reasonCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Explain why you need this access…',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: c.isSubmitting.value ? null : c.submitRequest,
                      child: c.isSubmitting.value
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Request',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )),
            ),

            // ── My Request History ────────────────────────────────────────────
            const SizedBox(height: 20),
            _sectionTitle('My Request History'),
            const SizedBox(height: 8),
            Obx(() {
              if (c.isLoadingReqs.value) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ));
              }
              if (c.myRequests.isEmpty) {
                return AppGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text('No requests submitted yet.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                );
              }
              return Column(
                children: c.myRequests.map((req) => _RequestHistoryCard(req: req)).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold));

  String _permLabel(String p) => switch (p) {
    'canEditProductInfo' => 'Edit product info',
    'canAddProduct'      => 'Add products',
    'canDeleteProduct'   => 'Delete products',
    _                    => p,
  };
}

// ── Permission Row ─────────────────────────────────────────────────────────────

class _PermRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool granted;
  final String? subtitle;

  const _PermRow(this.label, this.icon, this.granted, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    final color = granted ? Colors.green.shade400 : Colors.white30;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: granted ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Icon(
          granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color,
          size: 18,
        ),
      ],
    );
  }
}

// ── Generated Code Card ────────────────────────────────────────────────────────

class _GeneratedCodeCard extends StatelessWidget {
  final String code;
  final double percent;
  final String expiresAt;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  const _GeneratedCodeCard({
    required this.code,
    required this.percent,
    required this.expiresAt,
    required this.onCopy,
    required this.onDismiss,
  });

  String get _expiry {
    try {
      final dt = DateTime.parse(expiresAt).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return expiresAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.successSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.successBorder),
          ),
          child: Column(
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${percent.toStringAsFixed(0)}% discount  ·  expires at $_expiry',
                style: const TextStyle(color: AppColors.success, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text('Read this code aloud to the customer.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.successBorder),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Generate New'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Request History Card ───────────────────────────────────────────────────────

class _RequestHistoryCard extends StatelessWidget {
  final Map<String, dynamic> req;
  const _RequestHistoryCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final status = req['status'] as String? ?? 'pending';
    final statusColor = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      'revoked'  => AppColors.error,
      _          => AppColors.warning,
    };
    final typeLabel = switch (req['requestType'] as String? ?? '') {
      'discount'     => 'Discount',
      'product_edit' => 'Product Edit',
      'bulk_upload'  => 'Bulk Upload',
      _              => req['requestType'] ?? '',
    };

    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(typeLabel,
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(req['reason'] ?? '',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
          if (req['reviewNote'] != null && (req['reviewNote'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${req['reviewNote']}',
                style: TextStyle(color: statusColor.withValues(alpha: 0.9), fontSize: 11)),
          ],
          const SizedBox(height: 4),
          Text(_fmt(req['createdAt']),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  String _fmt(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}
