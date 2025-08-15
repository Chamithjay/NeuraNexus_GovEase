import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'educational_services_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? citizenId;
  const HomeScreen({super.key, this.citizenId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String citizenName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.citizenId != null && widget.citizenId!.isNotEmpty) {
      _fetchCitizenName();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCitizenName() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/citizens/${widget.citizenId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          citizenName = data['full_name'] ?? 'Citizen';
          isLoading = false;
        });
      } else {
        setState(() {
          citizenName = 'Citizen';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        citizenName = 'Citizen';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar replacement with title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GovEase',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Welcome Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1976D2).withOpacity(0.1),
                        const Color(0xFF42A5F5).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          size: 48,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLoading
                            ? 'Welcome to GovEase\nLoading...'
                            : widget.citizenId != null &&
                                  widget.citizenId!.isNotEmpty &&
                                  citizenName.isNotEmpty
                            ? 'Welcome to GovEase\n$citizenName'
                            : 'Welcome to GovEase',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your Digital Gateway to Government Services',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Main Services Section
                const Text(
                  'Government Services',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 16),

                // Service Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    _buildServiceCard(
                      context,
                      'Educational Services',
                      'School admissions, scholarships, exams & teacher services',
                      Icons.school,
                      const Color(0xFF4CAF50),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EducationalServicesScreen(),
                        ),
                      ),
                    ),
                    // Removed Admin Dashboard from citizen home
                    _buildServiceCard(
                      context,
                      'Health Services',
                      'Medical services, appointments & health records',
                      Icons.local_hospital,
                      const Color(0xFFE91E63),
                      () => _showComingSoon(context, 'Health Services'),
                    ),
                    _buildServiceCard(
                      context,
                      'Transport Services',
                      'License renewals, vehicle registration & permits',
                      Icons.directions_car,
                      const Color(0xFF2196F3),
                      () => _showComingSoon(context, 'Transport Services'),
                    ),
                    _buildServiceCard(
                      context,
                      'Citizen Services',
                      'ID cards, birth certificates & citizen registrations',
                      Icons.person,
                      const Color(0xFFFF9800),
                      () => _showComingSoon(context, 'Citizen Services'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick Access Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: const Color(0xFF1976D2),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Access',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickAccessItem(
                            Icons.help_outline,
                            'Help & Support',
                            () => _showComingSoon(context, 'Help & Support'),
                          ),
                          _buildQuickAccessItem(
                            Icons.notifications_outlined,
                            'Notifications',
                            () => _showComingSoon(context, 'Notifications'),
                          ),
                          _buildQuickAccessItem(
                            Icons.history,
                            'Application History',
                            () =>
                                _showComingSoon(context, 'Application History'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // System Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'All systems operational',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80), // Space for floating button
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

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF1976D2)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String serviceName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.construction, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Coming Soon'),
            ],
          ),
          content: Text('$serviceName will be available soon. Stay tuned!'),
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
