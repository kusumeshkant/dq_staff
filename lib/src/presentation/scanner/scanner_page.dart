import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import 'scanner_controller.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _cam = MobileScannerController();

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ScannerController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Customer QR'),
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
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) c.onBarcodeDetected(code);
            },
          ),

          // Scan overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Hint text
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at the customer\'s order QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          // Loading overlay
          Obx(() => c.isProcessing.value
              ? Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text('Looking up order...',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
