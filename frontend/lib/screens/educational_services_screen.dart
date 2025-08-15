import 'package:flutter/material.dart';
import 'teacher_transfer_screen.dart';
import 'auth_screen.dart';

class EducationalServicesScreen extends StatelessWidget {
  const EducationalServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with gradient background
                Container(
                  width: double.infinity,
                  height: 300, // Responsive height
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
                        // Status bar elements (top right)
                        Positioned(
                          right: 30,
                          top: 10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 16,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 25,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Back button (top left)
                        Positioned(
                          left: 30,
                          top: 10,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 54,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),

                        // Center content
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 80,
                          child: Column(
                            children: [
                              // GovEase title
                              const Text(
                                'GovEase',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Welcome Back text
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontFamily: 'Open Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // White section with Educational Services
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Educational Services title
                      const Text(
                        'Educational Services',
                        style: TextStyle(
                          color: Color(0xFF1A3251),
                          fontSize: 32,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          height: 1.78,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Services grid - responsive
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double cardWidth =
                              (constraints.maxWidth - 16) /
                              2; // 2 cards per row with gap
                          return Column(
                            children: [
                              // First row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildServiceCard(
                                    width: cardWidth,
                                    title: 'Grade 1',
                                    subtitle: 'Admissions',
                                    imageAsset:
                                        'assets/images/grade1.jpg', // Add your image here
                                    imageUrl: 'https://placehold.co/128x87',
                                    titleColor: const Color(0xFF1A3251),
                                    subtitleColor: const Color(0xFF354B66),
                                    onTap: () => _navigateToService(
                                      context,
                                      'Grade 1 Admissions',
                                    ),
                                  ),
                                  _buildServiceCard(
                                    width: cardWidth,
                                    title: 'Grade 6',
                                    subtitle: 'After Scholarship.',
                                    imageAsset:
                                        'assets/images/grade6.jpg', // Add your image here
                                    imageUrl: 'https://placehold.co/105x87',
                                    titleColor: const Color(0xFF1A3251),
                                    subtitleColor: const Color(0xFF7E7F81),
                                    isGrade6: true,
                                    onTap: () => _navigateToService(
                                      context,
                                      'Grade 5 Scholarship',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Second row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildServiceCard(
                                    width: cardWidth,
                                    title: 'A/L School Selection',
                                    imageAsset:
                                        'assets/images/al_school.jpg', // Add your image here
                                    imageUrl: 'https://placehold.co/93x90',
                                    titleColor: const Color(0xFF1A3251),
                                    onTap: () => _navigateToService(
                                      context,
                                      'A/L School Selection',
                                    ),
                                  ),
                                  _buildServiceCard(
                                    width: cardWidth,
                                    title: 'Teacher Transfers',
                                    imageAsset:
                                        'assets/images/teacher_transfer.jpg', // Add your image here
                                    imageUrl: 'https://placehold.co/142x85',
                                    titleColor: const Color(0xFF1A3251),
                                    onTap: () => _navigateToService(
                                      context,
                                      'Teacher Transfers',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 80), // Space for floating button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Logout Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required double width,
    required String title,
    String? subtitle,
    String? imageAsset,
    required String imageUrl,
    required Color titleColor,
    Color? subtitleColor,
    bool isGrade6 = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: width * 0.98, // Maintain aspect ratio
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(33),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x6DFFFFFF),
              blurRadius: 4,
              offset: Offset(-1, 1),
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Image container
            Container(
              width: width * 0.6,
              height: width * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  // Use imageAsset if available, fallback to network image
                  image: imageAsset != null
                      ? AssetImage(imageAsset) as ImageProvider
                      : NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: isGrade6
                    ? RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$title\n',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.10,
                              ),
                            ),
                            if (subtitle != null)
                              TextSpan(
                                text: subtitle,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                  fontFamily: 'Open Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 1.47,
                                ),
                              ),
                          ],
                        ),
                      )
                    : subtitle != null
                    ? RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.10,
                              ),
                            ),
                            const TextSpan(
                              text: ' ',
                              style: TextStyle(
                                color: Color(0xFF212529),
                                fontSize: 18,
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.10,
                              ),
                            ),
                            TextSpan(
                              text: subtitle,
                              style: TextStyle(
                                color: subtitleColor ?? titleColor,
                                fontSize: 18,
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.10,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.10,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _navigateToService(BuildContext context, String serviceName) {
    if (serviceName == 'Teacher Transfers') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TeacherTransferScreen()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.construction, color: Colors.orange),
              const SizedBox(width: 8),
              Text(serviceName),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$serviceName service is under development.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This service will be connected to the backend API and provide full functionality soon.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
