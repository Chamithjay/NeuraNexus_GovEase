// Updated application_form_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'school_selection_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  final String? selectedStream;

  ApplicationFormScreen({Key? key, this.selectedStream}) : super(key: key);

  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  String? selectedStream;
  List<FileUploadItem> uploadedFiles = [];
  bool isLoading = false;

  // Required documents (exactly 2)
  final List<String> requiredDocuments = [
    'OL result sheet',
    'NIC photographs (both sides)',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prioritize widget.selectedStream, fallback to route arguments
    selectedStream = widget.selectedStream ?? ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        // Clear existing files and add new ones (limit to 2)
        setState(() {
          uploadedFiles.clear();
        });

        int filesToAdd = result.files.length > 2 ? 2 : result.files.length;

        for (int i = 0; i < filesToAdd; i++) {
          PlatformFile file = result.files[i];
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

        if (result.files.length > 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only first 2 files were selected. Maximum 2 files allowed.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
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
    Future.delayed(Duration(milliseconds: 150), () {
      if (index < uploadedFiles.length && mounted) {
        setState(() {
          uploadedFiles[index].progress += 0.2;
          if (uploadedFiles[index].progress > 1.0) {
            uploadedFiles[index].progress = 1.0;
          }
        });

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

  bool _canProceed() {
    return uploadedFiles.length == 2 &&
        uploadedFiles.every((file) => file.progress >= 1.0) &&
        !isLoading &&
        selectedStream != null && selectedStream!.isNotEmpty;
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (uploadedFiles.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload exactly 2 documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!uploadedFiles.every((file) => file.progress >= 1.0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for all files to upload completely'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedStream == null || selectedStream!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stream not selected. Please go back and select a stream.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/school-selection',
      arguments: {
        'fullName': _fullNameController.text,
        'nic': _nicController.text,
        'stream': selectedStream,
        'files': uploadedFiles.map((f) => f.name).toList(),
      },
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
              Icon(_getFileIcon(file.name), color: Color(0xFF3B4B8C), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              file.progress >= 1.0 ? Colors.green : Color(0xFF3B4B8C),
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
          child: Column(
            children: [
              SizedBox(height: 20),
              
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Educational Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A/L Admissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pick the path that excites you most!\nYour subjects today will shape your tomorrow!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your preferred stream',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            selectedStream?.toUpperCase() ?? 'Not Selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Full Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(0xFFE9ECEF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(0xFF3B4B8C),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'NIC Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _nicController,
                            decoration: InputDecoration(
                              hintText: 'Enter your NIC number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(0xFFE9ECEF),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(0xFF3B4B8C),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your NIC number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Upload these files (All Required)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: requiredDocuments
                                .map((doc) => _buildRequirementItem(doc))
                                .toList(),
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickFiles,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFF3B4B8C),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload,
                                      size: 40,
                                      color: Color(0xFF74B9FF),
                                    ),
                                    SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF636E72),
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
                                        color: Color(0xFF95A5A6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          if (uploadedFiles.isNotEmpty) ...[
                            Row(
                              children: [
                                if (uploadedFiles.any(
                                  (file) => file.progress < 1.0,
                                )) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF3B4B8C),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ] else ...[
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                ],
                                Text(
                                  uploadedFiles.every(
                                        (file) => file.progress >= 1.0,
                                      )
                                      ? 'Upload Complete - ${uploadedFiles.length}/2 files'
                                      : 'Uploading - ${uploadedFiles.length}/2 files',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: uploadedFiles.every(
                                      (file) => file.progress >= 1.0,
                                    )
                                        ? Colors.green
                                        : Color(0xFF636E72),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                          if (uploadedFiles.isNotEmpty) ...[
                            ...uploadedFiles.asMap().entries.map((entry) {
                              return _buildFileItem(entry.value, entry.key);
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed()
                        ? Color(0xFF3B4B8C)
                        : Color(0xFFB0BEC5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NEXT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
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
}

class FileUploadItem {
  final String name;
  double progress;
  final PlatformFile? file;

  FileUploadItem({required this.name, required this.progress, this.file});
}