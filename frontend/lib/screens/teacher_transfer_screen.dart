import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'my_requests_screen.dart';

class TeacherTransferScreen extends StatefulWidget {
  const TeacherTransferScreen({super.key});

  @override
  State<TeacherTransferScreen> createState() => _TeacherTransferScreenState();
}

class _TeacherTransferScreenState extends State<TeacherTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teacherIdController = TextEditingController();
  final _currentDistrictController = TextEditingController();
  final _requestingDistrictController = TextEditingController();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _citizenIdController = TextEditingController();

  bool _isLoading = false;

  // FastAPI base URL (backend running at http://127.0.0.1:8000)
  static const String _baseUrl = 'http://127.0.0.1:8000';

  @override
  void dispose() {
    _teacherIdController.dispose();
    _currentDistrictController.dispose();
    _requestingDistrictController.dispose();
    _nameController.dispose();
    _reasonController.dispose();
    _citizenIdController.dispose();
    super.dispose();
  }

  Future<void> _getTeacherDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final id = _teacherIdController.text.trim();
      final uri = Uri.parse('$_baseUrl/api/teachers/$id');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        // Link citizen to teacher_id if citizen id provided
        final cid = _citizenIdController.text.trim();
        if (cid.isNotEmpty) {
          try {
            final linkUri = Uri.parse('$_baseUrl/api/citizens/$cid');
            final linkBody = json.encode({
              'teacher_id': data['teacher_id'],
              'citizen_type': 'Teacher',
            });
            await http.put(
              linkUri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: linkBody,
            );
          } catch (_) {}
        }
        _showTeacherDetailsPopup(data);
      } else if (res.statusCode == 404) {
        _showErrorDialog('Teacher not found');
      } else {
        _showErrorDialog('Request failed: ${res.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTeacherDetailsPopup(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teacher Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _kv('Teacher ID', t['teacher_id']),
                _kv('Name', t['teacher_name']),
                _kv('Current District', t['current_district']),
                _kv('School ID', t['school_id']),
                _kv('Subjects', (t['subjects'] as List?)?.join(', ')),
                _kv(
                  'Years in Service (District)',
                  t['years_in_service_district']?.toString(),
                ),
                const Divider(height: 24),
                const Text(
                  'Transfer Request',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _kv('From District', _currentDistrictController.text),
                _kv('Applicant Name', _nameController.text),
                _kv('Reason', _reasonController.text),
                _kv('Requesting District', _requestingDistrictController.text),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitTransferRequest(t);
              },
              child: const Text('Confirm & Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _kv(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: (value == null || value.isEmpty) ? 'N/A' : value),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransferRequest(Map<String, dynamic> teacherData) async {
    try {
      final createUri = Uri.parse('$_baseUrl/api/transfer-requests/');
      final body = json.encode({
        'teacher_id': teacherData['teacher_id'],
        'from_district': _currentDistrictController.text.trim(),
        'to_district': _requestingDistrictController.text.trim(),
      });
      final res = await http.post(
        createUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );
      if (res.statusCode != 201) {
        _showErrorDialog('Failed to submit request (${res.statusCode}).');
        return;
      }
      final Map<String, dynamic> created =
          json.decode(res.body) as Map<String, dynamic>;
      final requestId = created['request_id'] as String;

      // Check for match
      final matchUri = Uri.parse(
        '$_baseUrl/api/transfer-requests/match/$requestId',
      );
      final matchRes = await http.get(
        matchUri,
        headers: {'Accept': 'application/json'},
      );
      if (matchRes.statusCode == 200) {
        final Map<String, dynamic> payload =
            json.decode(matchRes.body) as Map<String, dynamic>;
        final matched = payload['matched'] == true;
        if (matched) {
          final matchReq = payload['match_request'] as Map<String, dynamic>;
          final matchedTeacher =
              payload['matched_teacher'] as Map<String, dynamic>?;
          final transferMatch =
              payload['transfer_match'] as Map<String, dynamic>?;
          _showMatchDialog(requestId, matchReq, matchedTeacher, transferMatch);
        } else {
          _showNoMatchDialog(requestId);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request submitted: $requestId (match check failed)'),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Network error submitting or matching request.');
    }
  }

  void _showMatchDialog(
    String requestId,
    Map<String, dynamic> matchReq,
    Map<String, dynamic>? matchedTeacher,
    Map<String, dynamic>? transferMatch,
  ) {
    // matchReq comes from backend TransferRequestResponse; additional matched_teacher details are fetched inline
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Matching Transfer Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Your Request ID', requestId),
            const SizedBox(height: 8),
            const Text('Matched request details:'),
            const SizedBox(height: 8),
            _kv('Match Request ID', matchReq['request_id']?.toString()),
            _kv('From', matchReq['from_district']?.toString()),
            _kv('To', matchReq['to_district']?.toString()),
            _kv('Status', matchReq['status']?.toString()),
            if (transferMatch != null) ...[
              const SizedBox(height: 8),
              _kv('Matching ID', transferMatch['matching_id']?.toString()),
              _kv('Match Status', transferMatch['match_status']?.toString()),
            ],
            const Divider(height: 18),
            if (matchedTeacher != null) ...[
              const Text(
                'Other Teacher:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _kv('Name', matchedTeacher['teacher_name']?.toString()),
              _kv(
                'Current District',
                matchedTeacher['current_district']?.toString(),
              ),
              _kv(
                'Years in Service (District)',
                matchedTeacher['years_in_service_district']?.toString(),
              ),
              _kv('Phone', matchedTeacher['phone']?.toString()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final matchingId = transferMatch != null
                    ? (transferMatch['matching_id']?.toString() ?? '')
                    : '';
                final uri = Uri.parse(
                  '$_baseUrl/api/transfer-requests/match/$matchingId/agree?request_id=${Uri.encodeComponent(requestId)}',
                );
                final res = await http.post(
                  uri,
                  headers: {'Accept': 'application/json'},
                );
                if (res.statusCode == 200) {
                  final Map<String, dynamic> m =
                      json.decode(res.body) as Map<String, dynamic>;
                  final status = (m['match_status'] ?? '').toString();
                  if (mounted) Navigator.of(context).pop();
                  final msg = status == 'AGREED'
                      ? 'Both teachers agreed. Admin will be notified.'
                      : 'Your agreement is recorded. Waiting for the other teacher.';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(msg)));
                } else {
                  _showErrorDialog(
                    'Failed to approve transfer (${res.statusCode}).',
                  );
                }
              } catch (e) {
                _showErrorDialog('Network error approving transfer.');
              }
            },
            child: const Text('I Agree to this Transfer'),
          ),
        ],
      ),
    );
  }

  void _showNoMatchDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Exact Match Found'),
        content: const Text(
          'There is no matching opposite transfer right now. Add to waiting list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final uri = Uri.parse(
                '$_baseUrl/api/transfer-requests/$requestId/waiting-list',
              );
              try {
                final res = await http.post(
                  uri,
                  headers: {'Accept': 'application/json'},
                );
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to waiting list: $requestId'),
                    ),
                  );
                } else {
                  _showErrorDialog(
                    'Failed to add to waiting list (${res.statusCode}).',
                  );
                }
              } catch (_) {
                _showErrorDialog('Network error adding to waiting list.');
              }
            },
            child: const Text('Add to Waiting List'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (same as Educational Services)
            Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A3251), Color(0xFF2B4A6B)],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      right: 30,
                      top: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 16,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 25,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 54,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 80,
                      child: Column(
                        children: const [
                          Text(
                            'GovEase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // White form section styled similarly
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teacher Transfer Application',
                      style: TextStyle(
                        color: Color(0xFF1A3251),
                        fontSize: 32,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        height: 1.78,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildField(
                      label: 'Teacher ID',
                      hint: 'Enter your Teacher ID',
                      controller: _teacherIdController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Teacher ID is required'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      label: 'Citizen ID (optional)',
                      hint: 'Enter your Citizen ID to link',
                      controller: _citizenIdController,
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      label: 'Current School (District)',
                      hint: 'Enter your current district',
                      controller: _currentDistrictController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Current district is required'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      label: 'Requesting District',
                      hint: 'Enter the district you are requesting',
                      controller: _requestingDistrictController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requesting district is required'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      label: 'Name with Initials',
                      hint: 'e.g., A.B.C. Perera',
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      label: 'Reason for Transfer',
                      hint: 'Explain the reason for transfer',
                      controller: _reasonController,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Reason is required'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getTeacherDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final id = _teacherIdController.text.trim();
                          if (id.isEmpty) {
                            _showErrorDialog(
                              'Enter Teacher ID to view requests',
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MyRequestsScreen(
                                teacherId: id,
                                baseUrl: _baseUrl,
                              ),
                            ),
                          );
                        },
                        child: const Text('View My Requests'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }
}
