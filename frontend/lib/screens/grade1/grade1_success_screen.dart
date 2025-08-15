import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this to pubspec.yaml


class ApplicationSuccessScreen extends StatefulWidget {
  final String referenceNumber;
  final Map<String, dynamic> applicationData;
  final Map<String, dynamic> paymentData;

  const ApplicationSuccessScreen({
    Key? key,
    required this.referenceNumber,
    required this.applicationData,
    required this.paymentData,
  }) : super(key: key);

  @override
  _ApplicationSuccessScreenState createState() => _ApplicationSuccessScreenState();
}

class _ApplicationSuccessScreenState extends State<ApplicationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 1.0, curve: Curves.easeIn),
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
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
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'GovEase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.home, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                ),

                // Content Card
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Success Animation
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 80,
                                    color: Colors.green[600],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 24),

                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Application Successful!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),

                                SizedBox(height: 8),

                                Text(
                                  'Your Grade 1 admission application has been successfully submitted and payment confirmed.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Reference Number Card
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Reference Number',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            widget.referenceNumber,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          IconButton(
                                            icon: Icon(Icons.copy, color: Colors.white),
                                            onPressed: () => _copyToClipboard(widget.referenceNumber),
                                            tooltip: 'Copy Reference Number',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 32),

                                // QR Code Section
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'QR Code for Quick Access',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: QrImageView(
                                          data: _generateQRData(),
                                          version: QrVersions.auto,
                                          size: 200.0,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Scan to check application status',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Payment Details
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.payment, color: Colors.green[600]),
                                          SizedBox(width: 8),
                                          Text(
                                            'Payment Confirmed',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      _buildPaymentDetailRow('Transaction ID', widget.paymentData['transaction_id'] ?? 'N/A'),
                                      _buildPaymentDetailRow('Amount Paid', 'LKR 500.00'),
                                      _buildPaymentDetailRow('Payment Method', 'PayPal'),
                                      _buildPaymentDetailRow('Date & Time', _formatDateTime(DateTime.now())),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Next Steps
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.orange[600]),
                                          SizedBox(width: 8),
                                          Text(
                                            'What\'s Next?',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      _buildNextStepItem('✓ Application review (3-5 business days)'),
                                      _buildNextStepItem('✓ Document verification'),
                                      _buildNextStepItem('✓ School allocation notification'),
                                      _buildNextStepItem('✓ SMS/Email updates on progress'),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Action Buttons
                                Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _downloadReceipt,
                                        icon: Icon(Icons.download, color: Colors.white),
                                        label: Text(
                                          'DOWNLOAD RECEIPT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF2E3B69),
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _trackApplication,
                                        icon: Icon(Icons.track_changes, color: Color(0xFF4FC3D7)),
                                        label: Text(
                                          'TRACK APPLICATION',
                                          style: TextStyle(
                                            color: Color(0xFF4FC3D7),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Color(0xFF4FC3D7), width: 2),
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                      icon: Icon(Icons.home, color: Colors.grey[600]),
                                      label: Text(
                                        'Back to Home',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  String _generateQRData() {
    return json.encode({
      'type': 'grade1_admission',
      'reference_number': widget.referenceNumber,
      'application_date': DateTime.now().toIso8601String(),
      'child_name': widget.applicationData['child_full_name'],
      'status': 'submitted',
      'tracking_url': 'https://govease.lk/track/${widget.referenceNumber}',
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Reference number copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _downloadReceipt() {
    // Implement PDF generation and download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt download started...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _trackApplication() {
    // Navigate to application tracking screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to application tracking...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}