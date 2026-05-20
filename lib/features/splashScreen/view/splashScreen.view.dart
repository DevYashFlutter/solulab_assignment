import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/splashScreen.controller.dart';

class SplashScreenView extends StatelessWidget {
  SplashScreenView({super.key});

  // Inject controller so that the timer starts on initialization
  final controller = Get.put(SplashScreenController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F56FA), // vibrant top blue
              Color(0xFF0C46C9), // rich bottom blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Center circle Logo
              const DocuScanLogo(),
              const SizedBox(height: 28),
              // DocuScan Text
              const Text(
                'DocuScan',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'Smart Document Scanner',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 36),
              // Sequential fading loading dots
              const LoadingDots(),
              const Spacer(flex: 4),
              // Powered by OCR text
              const Text(
                'Powered by OCR Technology',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class DocuScanLogo extends StatelessWidget {
  final double size;
  const DocuScanLogo({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.65,
          height: size * 0.65,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Tilted Card Icon
              Positioned(
                left: 10,
                top: 18,
                child: Transform.rotate(
                  angle: -0.18, // tilt slightly counter-clockwise
                  child: Container(
                    width: 62,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F56FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      children: [
                        // Card Stripe
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 6,
                            color: Colors.white.withAlpha(242),
                          ),
                        ),
                        // Small chip/signature details
                        Positioned(
                          bottom: 6,
                          left: 8,
                          child: Container(
                            width: 10,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(242),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Scanner Badge at bottom right of card
              Positioned(
                right: 8,
                bottom: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F56FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(38),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(12, 12),
                      painter: ReticlePainter(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = 3.0; // length of corner lines

    // Top-left
    canvas.drawLine(Offset(0, r), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(r, 0), paint);

    // Top-right
    canvas.drawLine(Offset(w - r, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, r), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, h - r), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(r, h), paint);

    // Bottom-right
    canvas.drawLine(Offset(w - r, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - r), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final double value = (sin((_controller.value * 2 * pi) - (delay * 2 * pi)) + 1) / 2;
            return Opacity(
              opacity: 0.3 + (value * 0.7),
              child: Transform.scale(
                scale: 0.8 + (value * 0.4),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
