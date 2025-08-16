import 'package:flutter/material.dart';
import 'grade1_start_screen.dart';
import '../advacedlevel/al_start_screen.dart';

class EducationalServicesScreen extends StatefulWidget {
  const EducationalServicesScreen({Key? key}) : super(key: key);

  @override
  _EducationalServicesScreenState createState() => _EducationalServicesScreenState();
}

class _EducationalServicesScreenState extends State<EducationalServicesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B4CB8),
              Color(0xFF4FC3D7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with time and status bar
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '9:41',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Icon(Icons.wifi, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full, color: Colors.white, size: 18),
                      ],
                    ),
                  ],
                ),
              ),

              // GovEase Header with Welcome Back
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'GovEase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Educational Services Title
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Educational Services',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // 4 Separate Service Cards
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // First Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildServiceCard(
                                  title: 'Grade 1\nAdmissions',
                                  iconPath: 'assets/images/grade1_icon.png', // <-- SET YOUR IMAGE HERE
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Grade1StartScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildServiceCard(
                                  title: 'Grade 6\nAfter Scholarship.',
                                  iconPath: 'assets/images/grade6_icon.png', // <-- SET YOUR IMAGE HERE
                                  onTap: () {
                                    _showComingSoon(context, 'Grade 6 Scholarship');
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          // Second Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildServiceCard(
                                  title: 'A/L School\nSelection',
                                  iconPath: 'assets/images/al_school_icon.png', // <-- SET YOUR IMAGE HERE
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WelcomeScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildServiceCard(
                                  title: 'Teacher\nTransfers',
                                  iconPath: 'assets/images/teacher_icon.png', // <-- SET YOUR IMAGE HERE
                                  onTap: () {
                                    _showComingSoon(context, 'Teacher Transfers');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image container
              Container(
                width: 80,
                height: 80,
                child: Image.asset(
                  iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image is not found
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF4FC3D7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getFallbackIcon(title),
                        size: 40,
                        color: Color.fromARGB(255, 118, 224, 243),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: 16),
              
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFallbackIcon(String title) {
    if (title.contains('Grade 1')) {
      return Icons.school;
    } else if (title.contains('Grade 6')) {
      return Icons.emoji_events;
    } else if (title.contains('A/L School')) {
      return Icons.assignment;
    } else {
      return Icons.person_outline;
    }
  }

  void _showComingSoon(BuildContext context, String service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4FC3D7)),
              SizedBox(width: 8),
              Text('Coming Soon'),
            ],
          ),
          content: Text(
            '$service service will be available soon. Stay tuned for updates!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF4FC3D7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}