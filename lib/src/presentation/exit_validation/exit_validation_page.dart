import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../../widgets/themed_background.dart';
import '../../../widgets/app_glass_card.dart';
import '../../domain/entity/order_entity.dart';
import 'exit_validation_controller.dart';

class ExitValidationPage extends StatefulWidget {
  const ExitValidationPage({super.key});

  @override
  State<ExitValidationPage> createState() => _ExitValidationPageState();
}

class _ExitValidationPageState extends State<ExitValidationPage> {
  final MobileScannerController _cam = MobileScannerController();

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitValidationController>();

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Exit Validation',
              style: TextStyle(color: AppTheme.textPrimary)),
          actions: [
            Obx(() => c.state.value == ExitValidationState.scanning
                ? IconButton(
                    icon: const Icon(Icons.flash_on_rounded,
                        color: AppTheme.textPrimary),
                    onPressed: () => _cam.toggleTorch(),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        body: Obx(() {
          final s = c.state.value;

          return switch (s) {
            ExitValidationState.idle     => _IdleView(onStart: c.startScanning),
            ExitValidationState.scanning => _ScannerView(cam: _cam, controller: c),
            ExitValidationState.loading  => _LoadingView(),
            ExitValidationState.approved => _ApprovedView(
                order: c.validatedOrder.value!,
                onNext: c.retryAfterResult,
              ),
            ExitValidationState.rejected => _RejectedView(
                reason: c.rejectionReason.value,
                onRetry: c.retryAfterResult,
              ),
          };
        }),
      ),
    );
  }
}

// ── Idle ──────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final VoidCallback onStart;
  const _IdleView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.teal, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Exit Validation',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan the customer\'s receipt QR code\nto verify payment before they exit.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Start Scanning',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scanner ───────────────────────────────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController cam;
  final ExitValidationController controller;

  const _ScannerView({required this.cam, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: cam,
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) controller.onQrDetected(code);
          },
        ),
        // Scan frame overlay
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Top dim bar
        Positioned(
          top: 0, left: 0, right: 0,
          height: MediaQuery.of(context).size.height / 2 - 130,
          child: Container(color: Colors.black54),
        ),
        // Bottom dim bar + hint
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: MediaQuery.of(context).size.height / 2 - 130,
          child: Container(
            color: Colors.black54,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 24),
            child: const Text(
              'Point camera at the customer\'s receipt QR',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
        // Cancel button
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Center(
            child: TextButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              label: const Text('Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.teal),
          SizedBox(height: 16),
          Text('Verifying payment...',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Approved ──────────────────────────────────────────────────────────────────

class _ApprovedView extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onNext;

  const _ApprovedView({required this.order, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final shortId =
        order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Green check
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.green.withValues(alpha: 0.5), width: 2.5),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 54),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Verified',
            style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Customer may exit',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 28),

          // Order summary card
          AppGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.storeName ?? 'Store',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Text('PAID',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.formattedDate,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ]),
                const Divider(color: Colors.white12, height: 20),

                // Items
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13)),
                          ),
                          Text(
                            '${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )),

                const Divider(color: Colors.white12, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('₹${order.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Order #$shortId',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Next Customer',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rejected ──────────────────────────────────────────────────────────────────

class _RejectedView extends StatelessWidget {
  final String reason;
  final VoidCallback onRetry;

  const _RejectedView({required this.reason, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.red.withValues(alpha: 0.5), width: 2.5),
            ),
            child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 54),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cannot Exit',
            style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          AppGlassCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Again',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
