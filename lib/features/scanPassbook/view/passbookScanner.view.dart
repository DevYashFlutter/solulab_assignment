import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/passbook_scanner.controller.dart';

class PassbookScannerView extends StatelessWidget {
  const PassbookScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PassbookScannerController());

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
          'Scan Bank Passbook',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final hasImage = controller.imagePath.value.isNotEmpty;
        final hasDetails = controller.bankDetails.value != null;
        final details = controller.bankDetails.value;
        final hasError = controller.errorMessage.value.isNotEmpty;
        final isLoading = controller.isProcessing.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SCANNING WINDOW / IMAGE PREVIEW
              AspectRatio(
                aspectRatio: 1.414, // standard A4/passbook document landscape ratio
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

                      // Document Guideline Frame
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasDetails ? const Color(0xFF10B981) : const Color(0xFF10B981).withValues(alpha: 0.4),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      // Scanning Laser animation
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
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCEEAD6)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981))),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Processing Document with OCR...',
                        style: TextStyle(color: Color(0xFF137333), fontWeight: FontWeight.w600, fontSize: 14),
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
                // 3. EXTRACTED BANK DETAILS PREVIEW
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
                      const Text(
                        'EXTRACTED BANK DETAILS',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                      // Account Holder Name
                      _DetailRow(
                        label: 'Account Holder Name',
                        value: details!.accountHolderName.isNotEmpty ? details.accountHolderName : 'Not Found',
                        valueColor: details.accountHolderName.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 16),

                      // Account Number
                      _DetailRow(
                        label: 'Account Number',
                        value: details.accountNumber.isNotEmpty ? details.accountNumber : 'Not Found',
                        isCode: details.accountNumber.isNotEmpty,
                        valueColor: details.accountNumber.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 16),

                      // IFSC Code
                      _DetailRow(
                        label: 'IFSC Code',
                        value: details.ifscCode.isNotEmpty ? details.ifscCode : 'Not Found',
                        isCode: details.ifscCode.isNotEmpty,
                        valueColor: details.ifscCode.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              if (!isLoading) ...[
                if (hasImage)
                  ElevatedButton(
                    onPressed: () => controller.reset(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F56FA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: const Color(0xFF0F56FA).withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Scan Another Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _SourceButton(
                          onTap: () => controller.captureAndScanPassbook(),
                          icon: Icons.photo_camera_rounded,
                          label: 'Capture & Scan',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SourceButton(
                          onTap: () => controller.uploadFromGallery(),
                          icon: Icons.photo_library_rounded,
                          label: 'Upload Image',
                          color: const Color(0xFF0F56FA),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  const _SourceButton({required this.onTap, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
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
            letterSpacing: isCode ? 1.0 : null,
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.08, end: 0.92).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
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
            height: 2.5,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 1.5)],
            ),
          ),
        );
      },
    );
  }
}
