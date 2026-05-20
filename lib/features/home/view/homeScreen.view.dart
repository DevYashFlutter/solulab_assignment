import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../scanCard/view/cardScanner.view.dart';
import '../../scanPassbook/view/passbookScanner.view.dart';

class HomeScreenView extends StatelessWidget {
  const HomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header Title
                const Text(
                  'Document Scanner',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                // Header Subtitle
                const Text(
                  'Scan cards and passbooks with OCR',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                // Divider
                const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                const SizedBox(height: 24),
                // Card 1: Scan Card
                _buildActionCard(
                  title: 'Scan Card',
                  subtitle: 'Extract card number, expiry, and name',
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF0F56FA),
                  iconBgColor: const Color(0xFFE8EFFF),
                  onTap: () {
                    Get.to(() => const CardScannerView());
                  },
                ),
                const SizedBox(height: 16),
                // Card 2: Scan Passbook
                _buildActionCard(
                  title: 'Scan Passbook',
                  subtitle: 'Extract account number, IFSC, and name',
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: const Color(0xFFE6F7ED),
                  onTap: () {
                    Get.to(() => const PassbookScannerView());
                  },
                ),
                const SizedBox(height: 32),
                // How It Works Box
                _buildHowItWorksBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withAlpha(10), blurRadius: 16, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFF0F172A).withAlpha(5), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withAlpha(13),
          highlightColor: iconColor.withAlpha(5),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: Center(child: Icon(icon, color: iconColor, size: 24)),
                ),
                const SizedBox(width: 16),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksBox() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        border: Border.all(color: const Color(0xFFD0E7FF), width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F56FA)),
          ),
          const SizedBox(height: 14),
          _buildHowItWorksItem('Capture image using camera or upload'),
          const SizedBox(height: 8),
          _buildHowItWorksItem('OCR extracts text from the image'),
          const SizedBox(height: 8),
          _buildHowItWorksItem('Custom parsing algorithms structure the data'),
          const SizedBox(height: 8),
          _buildHowItWorksItem('Validated results are displayed clearly'),
        ],
      ),
    );
  }

  Widget _buildHowItWorksItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Text(
            '• ',
            style: TextStyle(color: Color(0xFF0F56FA), fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, height: 1.4, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
