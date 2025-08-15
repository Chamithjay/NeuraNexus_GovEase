import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'grade1_summary_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  final Map<String, dynamic> applicationData;

  const DocumentUploadScreen({Key? key, required this.applicationData})
    : super(key: key);

  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  List<FileUploadItem> uploadedFiles = [];
  bool _isSubmitting = false;

  // Required documents
  final List<String> requiredDocuments = [
    'Birth certificate',
    'Parent NIC(Both Sides)',
    'Proof of address',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B4CB8), // Dark blue
              Color(0xFF4FC3D7), // Light blue/cyan
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
                      'GovEase',
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
                      // Service Title
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Educational Services',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Grade 1 Admission',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Upload Section
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(16),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Upload Instructions
                              Text(
                                'Upload these files(All Required)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),

                              // Required Files List
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: requiredDocuments
                                    .map((doc) => _buildRequirementItem(doc))
                                    .toList(),
                              ),

                              SizedBox(height: 20),

                              // Drop Zone
                              GestureDetector(
                                onTap: _pickFiles,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color(0xFF4FC3D7),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 32,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Drag & drop files or ',
                                              ),
                                              TextSpan(
                                                text: 'Browse',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Supported formats: JPEG, PNG, PDF, Word',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // Upload Progress
                              if (uploadedFiles.isNotEmpty) ...[
                                Text(
                                  'Uploading - ${uploadedFiles.length}/${requiredDocuments.length} files',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],

                              // File List
                              Expanded(
                                child: uploadedFiles.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No files selected',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: uploadedFiles.length,
                                        itemBuilder: (context, index) {
                                          return _buildFileItem(
                                            uploadedFiles[index],
                                            index,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Upload Button
                      Container(
                        margin: EdgeInsets.all(16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canSubmit() ? _submitApplication : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSubmit()
                                ? Color(0xFF2E3B69)
                                : Colors.grey[400],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'SUBMIT APPLICATION',
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

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileUploadItem file, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getFileIcon(file.name), color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                onPressed: () => _removeFile(index),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: file.progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              file.progress >= 1.0 ? Colors.green : Color(0xFF4FC3D7),
            ),
            minHeight: 4,
          ),
          if (file.progress >= 1.0) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  'Upload complete',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
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

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.name != null) {
            FileUploadItem newFile = FileUploadItem(
              name: file.name!,
              progress: 0.0,
              file: file,
            );

            setState(() {
              uploadedFiles.add(newFile);
            });

            // Simulate file upload progress
            _simulateUploadProgress(uploadedFiles.length - 1);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

void _simulateUploadProgress(int index) {
  Future.delayed(Duration(milliseconds: 100), () {
    if (index < uploadedFiles.length && mounted) {
      setState(() {
        // Increment progress quickly for testing
        uploadedFiles[index].progress += 0.25; // faster for testing
        if (uploadedFiles[index].progress > 1.0) {
          uploadedFiles[index].progress = 1.0;
        }
      });

      // Repeat until progress reaches 100%
      if (uploadedFiles[index].progress < 1.0) {
        _simulateUploadProgress(index);
      }
    }
  });
}
  void _removeFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
  }

 bool _canSubmit() {
  return uploadedFiles.length >= requiredDocuments.length && 
         uploadedFiles.every((file) => file.progress >= 1.0) &&
         !_isSubmitting;
}

Future<void> _submitApplication() async {
  setState(() {
    _isSubmitting = true;
  });

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.56.1:8000/grade1_admission/apply'),
    );

    // Add form fields
    request.fields['child_full_name'] = widget.applicationData['child_full_name'];
    request.fields['date_of_birth'] = widget.applicationData['date_of_birth'];
    request.fields['parent_name'] = widget.applicationData['parent_guardian_name'];
    request.fields['guardian_nic'] = widget.applicationData['guardian_nic'];
    request.fields['contact_number'] = widget.applicationData['contact_number'];
    request.fields['school_name'] = widget.applicationData['school_name'] ?? '';
    request.fields['school_id'] = widget.applicationData['school_id'] ?? '';

    // Add files
    for (var fileItem in uploadedFiles) {
      if (fileItem.file != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            fileItem.file!.bytes!,
            filename: fileItem.name,
          ),
        );
      }
    }

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(responseBody);
      String referenceNumber = responseData['reference_number'] ?? 'N/A';
      
      // Navigate to summary screen instead of showing dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ApplicationSummaryScreen(
            applicationData: widget.applicationData,
            referenceNumber: referenceNumber,
          ),
        ),
      );
      
    } else {
      throw Exception('Failed to submit application: ${response.statusCode}');
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
      _isSubmitting = false;
    });
  }
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
              Text(
                'Application ID: $applicationId',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You will receive a confirmation shortly.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK', style: TextStyle(color: Color(0xFF3F51B5))),
            ),
          ],
        );
      },
    );
  }
}

class FileUploadItem {
  final String name;
  double progress;
  final PlatformFile? file;

  FileUploadItem({required this.name, required this.progress, this.file});
}
