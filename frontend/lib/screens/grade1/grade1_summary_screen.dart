import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_verification_screen.dart';

class ApplicationSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> applicationData;
  final String referenceNumber;

  const ApplicationSummaryScreen({
    Key? key,
    required this.applicationData,
    required this.referenceNumber,
  }) : super(key: key);

  @override
  _ApplicationSummaryScreenState createState() => _ApplicationSummaryScreenState();
}

class _ApplicationSummaryScreenState extends State<ApplicationSummaryScreen> {
  bool _isProcessingPayment = false;
  final double applicationFee = 150.00; // LKR

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
              // Header
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Application Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                  child: Column(
                    children: [
                      // Reference Number
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_turned_in, 
                                 color: Colors.green, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Application Submitted Successfully',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Reference: ${widget.referenceNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Summary Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Application Details
                              _buildSectionTitle('Application Details'),
                              _buildDetailRow('Service', 'Grade 1 Admission'),
                              _buildDetailRow('Child Name', widget.applicationData['child_full_name']),
                              _buildDetailRow('Date of Birth', widget.applicationData['date_of_birth']),
                              _buildDetailRow('Parent/Guardian', widget.applicationData['parent_guardian_name']),
                              _buildDetailRow('Contact Number', widget.applicationData['contact_number']),
                              _buildDetailRow('Guardian NIC', widget.applicationData['guardian_nic']),
                              if (widget.applicationData['school_name'] != null)
                                _buildDetailRow('Preferred School', widget.applicationData['school_name']),

                              SizedBox(height: 24),

                              // Payment Details
                              _buildSectionTitle('Payment Details'),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Application Processing Fee',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'LKR ${applicationFee.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'LKR ${applicationFee.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              // Payment Methods
                              _buildSectionTitle('Select Payment Method'),
                              _buildPaymentMethodCard(
                                'PayPal',
                                'Secure online payment',
                                Icons.payment,
                                Colors.blue[700]!,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Payment Button
                      Container(
                        margin: EdgeInsets.all(16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessingPayment ? null : _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E3B69),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isProcessingPayment
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'PROCEED TO PAYMENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  Widget _buildPaymentMethodCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Radio<bool>(
            value: true,
            groupValue: true,
            onChanged: (value) {},
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Call your FastAPI endpoint to create PayPal payment
      final response = await http.post(
        Uri.parse('http://192.168.56.1:8000/payment/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reference_number': widget.referenceNumber,
          'amount': applicationFee,
          'currency': 'USD', // PayPal typically uses USD
          'description': 'Grade 1 Admission Application Fee',
        }),
      );

      if (response.statusCode == 200) {
        final paymentData = json.decode(response.body);
        
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              referenceNumber: widget.referenceNumber,
              applicationData: widget.applicationData,
              paymentId: paymentData['payment_id'],
            ),
          ),
        );
      } else {
        throw Exception('Payment creation failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }
}