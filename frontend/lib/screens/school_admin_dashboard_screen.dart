import 'package:flutter/material.dart';

import '../widgets/govease_header.dart';
import 'auth_screen.dart';

class SchoolAdminDashboardScreen extends StatelessWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const GovEaseHeader(
                height: 220,
                subtitle: 'Administration',
                sectionTitle: 'School Admin Dashboard',
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'School Administration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.construction,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'School Dashboard Coming Soon',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'School-specific analytics and management features will be available here.',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
      backgroundColor: const Color(0xFFF4F6F9),
    );
  }
}
