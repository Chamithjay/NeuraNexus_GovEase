import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SummaryScreen extends StatefulWidget {
  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String fullName = '';
  String nic = '';
  String stream = '';
  String school = '';
  String selectedDistrict = '';
  List<String> files = [];
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      fullName = args['fullName'] ?? '';
      nic = args['nic'] ?? '';
      stream =
          args['stream'] ?? ''; // This should now properly receive the stream
      school = args['school'] ?? '';
      selectedDistrict = args['selectedDistrict'] ?? '';
      files = List<String>.from(args['files'] ?? []);

      // Debug print to check if stream is received
      print('Summary Screen - Received stream: $stream');
      print('Summary Screen - All args: $args');
    }
  }

  Future<void> _submitApplication() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fixed: Proper JSON encoding and correct API endpoint
      var response = await http.post(
        Uri.parse('http://127.0.0.1:8000/al_schools/apply'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "nic": nic,
          "preferred_stream": stream, // Make sure stream is sent to backend
          "selected_school": school,
          "files": files,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Navigate to payment page with application data including stream
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'applicationId':
                responseData['application_id'] ??
                'APP${DateTime.now().millisecondsSinceEpoch}',
            'fullName': fullName,
            'amount': 150.00, // A/L application fee
            'description': 'A/L School Application Fee',
            'school': school,
            'stream': stream, // Pass stream to payment page
            'district': selectedDistrict,
          },
        );
      } else {
        throw Exception('Failed to submit application: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3B4B8C),
      appBar: AppBar(
        backgroundColor: Color(0xFF3B4B8C),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GovEase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4B8C), Color(0xFF4A90E2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Application Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please review your information before proceeding to payment',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 20),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Application Details Section
                          _buildSectionHeader('Personal Information'),
                          SizedBox(height: 12),
                          _buildSummaryItem('Full Name', fullName),
                          _buildSummaryItem('NIC Number', nic),

                          SizedBox(height: 20),
                          _buildSectionHeader('Academic Information'),
                          SizedBox(height: 12),
                          _buildSummaryItem(
                            'Preferred Stream',
                            stream.isNotEmpty
                                ? stream.toUpperCase()
                                : 'Not Selected',
                          ),
                          _buildSummaryItem('Selected School', school),
                          if (selectedDistrict.isNotEmpty)
                            _buildSummaryItem('District', selectedDistrict),

                          SizedBox(height: 20),
                          _buildSectionHeader('Uploaded Documents'),
                          SizedBox(height: 12),
                          if (files.isEmpty)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'No documents uploaded',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...files
                                .map((file) => _buildFileItem(file))
                                .toList(),

                          SizedBox(height: 20),
                          _buildSectionHeader('Payment Information'),
                          SizedBox(height: 12),
                          _buildSummaryItem('Application Fee', 'LKR 130.00'),
                          _buildSummaryItem('Processing Fee', 'LKR 20.00'),
                          Divider(),
                          _buildSummaryItem(
                            'Total Amount',
                            'LKR 150.00',
                            isTotal: true,
                          ),

                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[700],
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Important Notice',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please review your information carefully. Once submitted, you will be redirected to the payment gateway to complete your application. After payment, changes cannot be made to your application.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B4B8C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'PROCESSING...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'PROCEED TO PAYMENT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.payment, size: 20),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3B4B8C),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isTotal = false}) {
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
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? Colors.black87 : Colors.grey[700],
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isTotal ? Colors.black87 : Colors.black87,
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(String fileName) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(_getFileIcon(fileName), color: Color(0xFF3B4B8C), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(fileName, style: TextStyle(color: Colors.black87)),
            ),
            Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
