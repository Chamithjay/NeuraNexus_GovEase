import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'grade1_document_upload_screen.dart';
class ApplicationFormScreen extends StatefulWidget {
  final String schoolName;
  final String schoolId;

  const ApplicationFormScreen({
    Key? key,
    required this.schoolName,
    required this.schoolId,
  }) : super(key: key);

  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _contactController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _childNameController.dispose();
    _dateOfBirthController.dispose();
    _parentNameController.dispose();
    _nicController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2018), // Default to 2018 for Grade 1 students
      firstDate: DateTime(2015),
      lastDate: DateTime(2020),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF3F51B5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = 
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

Future<void> _submitApplication() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // Prepare application data (DON'T submit to API yet)
  final applicationData = {
    'school_id': widget.schoolId,
    'school_name': widget.schoolName,
    'child_full_name': _childNameController.text.trim(),
    'date_of_birth': _dateOfBirthController.text.trim(),
    'parent_guardian_name': _parentNameController.text.trim(),
    'guardian_nic': _nicController.text.trim(),
    'contact_number': _contactController.text.trim(),
  };

  // Navigate to document upload screen instead of API call
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DocumentUploadScreen(
        applicationData: applicationData,
      ),
    ),
  );
}
  void _showSuccessDialog(String applicationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Application Submitted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your application has been successfully submitted!'),
              SizedBox(height: 8),
              Text('Application ID: $applicationId'),
              SizedBox(height: 8),
              Text('You will receive a confirmation shortly.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst); // Go back to main screen
              },
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFF3F51B5)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3F51B5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'GovEase',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3F51B5),
              Color(0xFF5C6BC0),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Educational Services',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Grade 1 Admission',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Container
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    controller: _childNameController,
                                    label: "Child's full name",
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter child\'s full name';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  
                                  _buildDateField(),
                                  SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _parentNameController,
                                    label: "Parent/guardian name",
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter parent/guardian name';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _nicController,
                                    label: "Guardian's NIC number",
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter NIC number';
                                      }
                                      if (value.length != 10 && value.length != 12) {
                                        return 'Please enter a valid NIC number';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _contactController,
                                    label: "Contact number",
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter contact number';
                                      }
                                      if (value.length < 10) {
                                        return 'Please enter a valid contact number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitApplication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2E3A87),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'NEXT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, color: Colors.white),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3F51B5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of birth',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _dateOfBirthController,
          readOnly: true,
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select date of birth';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3F51B5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}