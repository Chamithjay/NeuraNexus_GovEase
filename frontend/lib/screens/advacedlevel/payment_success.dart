import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this to pubspec.yaml

class ALPaymentSuccessScreen extends StatefulWidget {
  @override
  _ALPaymentSuccessScreenState createState() => _ALPaymentSuccessScreenState();
}

class _ALPaymentSuccessScreenState extends State<ALPaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String applicationId = '';
  String fullName = '';
  double amount = 0.0;
  String paymentMethod = '';
  String transactionId = '';
  String school = '';
  String stream = '';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      applicationId = args['applicationId'] ?? '';
      fullName = args['fullName'] ?? '';
      amount = args['amount'] ?? 0.0;
      paymentMethod = args['paymentMethod'] ?? '';
      transactionId = args['transactionId'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
      school = args['school'] ?? '';
      stream = args['stream'] ?? '';
    }
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
                Color(0xFF3B4B8C),
                Color(0xFF4A90E2),
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
                        textAlign: TextAlign.center,
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
                                  'Payment Successful!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),

                                SizedBox(height: 8),

                                Text(
                                  'Your A/L school application payment has been successfully processed. You will receive updates on your application status.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Application ID Card
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF3B4B8C), Color(0xFF4A90E2)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF3B4B8C).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Application Reference',
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
                                            applicationId,
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
                                            onPressed: () => _copyToClipboard(applicationId),
                                            tooltip: 'Copy Application ID',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Application Details
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.school, color: Colors.blue[600]),
                                          SizedBox(width: 8),
                                          Text(
                                            'Application Details',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      _buildDetailRow('Student Name', fullName),
                                      _buildDetailRow('Stream', stream.toUpperCase()),
                                      _buildDetailRow('Selected School', school),
                                      _buildDetailRow('Application Date', _formatDateTime(DateTime.now())),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 24),

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
                                      _buildDetailRow('Transaction ID', transactionId),
                                      _buildDetailRow('Amount Paid', 'LKR ${amount.toStringAsFixed(2)}'),
                                      _buildDetailRow('Payment Method', _getPaymentMethodName(paymentMethod)),
                                      _buildDetailRow('Date & Time', _formatDateTime(DateTime.now())),
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
                                      _buildNextStepItem('✓ Document verification (2-3 business days)'),
                                      _buildNextStepItem('✓ Application review by selected school'),
                                      _buildNextStepItem('✓ School allocation notification'),
                                      _buildNextStepItem('✓ SMS/Email updates on progress'),
                                      _buildNextStepItem('✓ Registration process (if selected)'),
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
                                          backgroundColor: Color(0xFF3B4B8C),
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
                                        icon: Icon(Icons.track_changes, color: Color(0xFF4A90E2)),
                                        label: Text(
                                          'TRACK APPLICATION',
                                          style: TextStyle(
                                            color: Color(0xFF4A90E2),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Color(0xFF4A90E2), width: 2),
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

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
      'type': 'al_admission',
      'application_id': applicationId,
      'application_date': DateTime.now().toIso8601String(),
      'student_name': fullName,
      'stream': stream,
      'school': school,
      'status': 'payment_completed',
      'tracking_url': 'https://govease.lk/al-track/$applicationId',
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'visa':
        return 'Visa/Mastercard';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'digital_wallet':
        return 'Digital Wallet';
      default:
        return method.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Application ID copied to clipboard'),
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