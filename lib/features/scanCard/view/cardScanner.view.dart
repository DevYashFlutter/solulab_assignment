import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/card_scanner.controller.dart';

class CardScannerView extends StatelessWidget {
  const CardScannerView({super.key});

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) return 'XXXX XXXX XXXX XXXX';
    if (cardNumber.length < 4) return cardNumber;
    String lastFour = cardNumber.substring(cardNumber.length - 4);
    if (cardNumber.length <= 16) {
      return 'XXXX XXXX XXXX $lastFour';
    } else {
      // For longer cards
      return 'XXXX XXXX XXXX XXXX $lastFour';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CardScannerController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Scan Credit/Debit Card',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final hasImage = controller.imagePath.value.isNotEmpty;
        final hasDetails = controller.cardDetails.value != null;
        final details = controller.cardDetails.value;
        final hasError = controller.errorMessage.value.isNotEmpty;
        final isLoading = controller.isProcessing.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SCANNING WINDOW / IMAGE PREVIEW
              AspectRatio(
                aspectRatio: 1.586, // standard credit card aspect ratio
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155), width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (hasImage)
                        Image.file(File(controller.imagePath.value), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      else if (controller.isCameraInitialized.value && controller.cameraController != null)
                        Positioned.fill(
                          child: ClipRect(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: controller.cameraController!.value.previewSize?.height ?? 720,
                                height: controller.cameraController!.value.previewSize?.width ?? 1280,
                                child: CameraPreview(controller.cameraController!),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)),
                              ),
                              const SizedBox(height: 12),
                              Text('Starting camera...', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                            ],
                          ),
                        ),

                      // Card Frame Border Overlay
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasDetails && details!.isValid ? const Color(0xFF10B981) : const Color(0xFF0F56FA).withValues(alpha: 0.8),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Active Scanning Animation laser bar if processing
                      if (isLoading) const _ScanningLaserLine(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. STATUS / ERROR CONTAINER
              if (isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F56FA))),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Processing card with OCR...',
                        style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else if (hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(controller.errorMessage.value, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
                ),

              if (hasDetails && !isLoading) ...[
                const SizedBox(height: 12),
                // 3. EXTRACTED CARD PREVIEW
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EXTRACTED DATA',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          // Luhn Validation Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: details!.isValid ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  details.isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 14,
                                  color: details.isValid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  details.isValid ? 'Luhn Valid' : 'Luhn Invalid',
                                  style: TextStyle(
                                    color: details.isValid ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                      // Card Number Details
                      _DetailRow(label: 'Card Number', value: _maskCardNumber(details.cardNumber), isCode: true, valueColor: const Color(0xFF0F172A)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _DetailRow(
                              label: 'Expiry Date',
                              value: details.expiryDate.isNotEmpty ? details.expiryDate : 'Not Found',
                              valueColor: details.expiryDate.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DetailRow(
                              label: 'Card Holder',
                              value: details.cardHolderName.isNotEmpty ? details.cardHolderName : 'Not Found',
                              valueColor: details.cardHolderName.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // 4. SCAN BUTTON / CONTROL ACTIONS
              if (!isLoading)
                ElevatedButton(
                  onPressed: () {
                    if (hasImage) {
                      controller.reset();
                    } else {
                      controller.captureAndScanCard();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F56FA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor: const Color(0xFF0F56FA).withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(hasImage ? Icons.refresh_rounded : Icons.photo_camera_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(hasImage ? 'Scan Another Card' : 'Capture & Scan Card', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              if (hasImage && !isLoading) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => controller.reset(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Reset Scanner',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCode;
  final Color valueColor;

  const _DetailRow({required this.label, required this.value, this.isCode = false, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: isCode ? 'Courier' : null,
            letterSpacing: isCode ? 1.5 : null,
          ),
        ),
      ],
    );
  }
}

class _ScanningLaserLine extends StatefulWidget {
  const _ScanningLaserLine();

  @override
  State<_ScanningLaserLine> createState() => _ScanningLaserLineState();
}

class _ScanningLaserLineState extends State<_ScanningLaserLine> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, (_animation.value * 2) - 1),
          child: Container(
            height: 3,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              color: const Color(0xFF0F56FA),
              boxShadow: [BoxShadow(color: const Color(0xFF0F56FA).withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 2)],
            ),
          ),
        );
      },
    );
  }
}
