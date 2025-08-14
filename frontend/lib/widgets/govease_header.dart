import 'package:flutter/material.dart';

class GovEaseHeader extends StatelessWidget {
  final double height;
  final String subtitle; // e.g., Educational Services
  final String sectionTitle; // e.g., Teacher Transfers
  final VoidCallback? onBack;
  final VoidCallback? onNotifications;

  const GovEaseHeader({
    super.key,
    this.height = 220,
    this.subtitle = '',
    this.sectionTitle = '',
    this.onBack,
    this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3251), Color(0xFF2B4A6B)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (onBack != null)
              Positioned(
                left: 16,
                top: 10,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            if (onNotifications != null)
              Positioned(
                right: 16,
                top: 10,
                child: IconButton(
                  onPressed: onNotifications,
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 60,
              child: Column(
                children: [
                  const Text(
                    'GovEase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (sectionTitle.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      sectionTitle,
                      style: const TextStyle(
                        color: Color(0xFF0E2B51),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
