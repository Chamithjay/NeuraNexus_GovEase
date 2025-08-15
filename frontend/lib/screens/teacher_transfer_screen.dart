import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/govease_header.dart';
import 'my_requests_screen.dart';
import 'my_notifications_screen.dart';
import 'auth_screen.dart';

class TeacherTransferScreen extends StatefulWidget {
  const TeacherTransferScreen({super.key});

  @override
  State<TeacherTransferScreen> createState() => _TeacherTransferScreenState();
}

class _TeacherTransferScreenState extends State<TeacherTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teacherIdController = TextEditingController();
  final _citizenIdController = TextEditingController();
  final _currentDistrictController = TextEditingController();
  final _requestingDistrictController = TextEditingController();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isLoading = false;

  // TODO: consider centralizing config
  final String _baseUrl = 'http://localhost:8000';

  @override
  void dispose() {
    _teacherIdController.dispose();
    _citizenIdController.dispose();
    _currentDistrictController.dispose();
    _requestingDistrictController.dispose();
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                GovEaseHeader(
                  height: 260,
                  subtitle: 'Educational Services',
                  sectionTitle: 'Teacher Transfers',
                  onBack: () => Navigator.pop(context),
                  onNotifications: () {
                    final cid = _citizenIdController.text.trim();
                    if (cid.isEmpty) {
                      _showErrorDialog('Enter your Citizen ID to view notifications');
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MyNotificationsScreen(
                          citizenId: cid,
                          baseUrl: _baseUrl,
                        ),
                      ),
                    );
                  },
                ),

                // White form section
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
                                _showErrorDialog('Enter Teacher ID to view requests');
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
                
                const SizedBox(height: 80), // Space for floating button
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator()),
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
      backgroundColor: const Color(0xFFF4F6F9),
    );
  }

  Future<void> _getTeacherDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final id = _teacherIdController.text.trim();
      final reqDistrict = _requestingDistrictController.text.trim();

      // 1) Pre-check: block if teacher already has a Waiting List request to the same district
      try {
        final listUri = Uri.parse('$_baseUrl/api/transfer-requests/teacher/${Uri.encodeComponent(id)}');
        final listRes = await http.get(listUri, headers: {'Accept': 'application/json'});
        if (listRes.statusCode == 200) {
          final List<dynamic> data = json.decode(listRes.body) as List<dynamic>;
          String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
          final wantTo = norm(reqDistrict);
          final hasSameWaiting = data.any((e) {
            final m = e as Map<String, dynamic>;
            final status = norm((m['status'] ?? '').toString());
            final to = norm((m['to_district'] ?? '').toString());
            return (status == 'waitinglist' || status == 'waiting' || status == 'waitingqueue') && to == wantTo;
          });
          if (hasSameWaiting) {
            _showErrorDialog('You already have a transfer request to "$reqDistrict" in the Waiting List. You cannot submit another request for the same district.');
            return;
          }
        }
      } catch (_) {
        // If this pre-check fails, we continue to fetch teacher details.
      }

      // 2) Fetch teacher details as usual
      final uri = Uri.parse('$_baseUrl/api/teachers/${Uri.encodeComponent(id)}');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> t = json.decode(res.body) as Map<String, dynamic>;
        // Eligibility gate: require at least 5 years in service in district
        final years = ((t['years_in_service_district'] ?? 0) as num).toInt();
        if (years < 5) {
          _showErrorDialog('Ineligible for transfer: requires at least 5 years in the current district (Current: $years).');
          return;
        }
        _showTeacherConfirmDialog(t);
      } else if (res.statusCode == 404) {
        _showErrorDialog('Teacher not found.');
      } else {
        _showErrorDialog('Failed to fetch teacher (${res.statusCode}).');
      }
    } catch (_) {
      _showErrorDialog('Network error fetching teacher.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTeacherConfirmDialog(Map<String, dynamic> t) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final years = ((t['years_in_service_district'] ?? 0) as num).toInt();
    final eligible = years >= 5;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.12,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.76,
            maxWidth: screenWidth * 0.84,
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.person, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Teacher Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Eligibility banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: eligible ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    border: Border.all(color: eligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(eligible ? Icons.verified : Icons.block,
                          color: eligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          eligible
                              ? 'Eligible for transfer ($years years in district)'
                              : 'Ineligible: requires ≥5 years (current: $years)',
                          style: TextStyle(
                            color: eligible ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Teacher info in organized sections
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with teacher name
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A3251), Color(0xFF2B4A6B)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t['teacher_name']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ID: ${t['teacher_id']}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Basic Information Section
                      _buildInfoSection(
                        title: 'Basic Information',
                        icon: Icons.info_outline,
                        color: const Color(0xFF059669),
                        items: [
                          _buildDetailRow('Current District', t['current_district']),
                          _buildDetailRow('School ID', t['school_id']),
                          _buildDetailRow('Years in District', years.toString()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Academic Information Section
                      _buildInfoSection(
                        title: 'Academic Details',
                        icon: Icons.school,
                        color: const Color(0xFF7C3AED),
                        items: [
                          _buildDetailRow('Subjects', (t['subjects'] as List?)?.join(', ') ?? 'N/A'),
                          _buildDetailRow('Teaching Experience', '$years years'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Contact Information Section
                      if (t['phone'] != null) ...[
                        _buildInfoSection(
                          title: 'Contact Information',
                          icon: Icons.contact_phone,
                          color: const Color(0xFFF59E0B),
                          items: [
                            _buildDetailRow('Phone', t['phone']),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Request summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3251).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A3251).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer Request Summary',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text('${_currentDistrictController.text} → ${_requestingDistrictController.text}',
                           style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Applicant: ${_nameController.text}', style: const TextStyle(fontSize: 13)),
                      if (_reasonController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Reason: ${_reasonController.text}', 
                             style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    if (eligible) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _submitTransferRequest(t);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3251),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirm & Submit'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactInfoTile(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value?.toString() ?? 'N/A',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
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
      final Map<String, dynamic> created = json.decode(res.body) as Map<String, dynamic>;
      final requestId = created['request_id'] as String;

      // Check for match
      final matchUri = Uri.parse('$_baseUrl/api/transfer-requests/match/$requestId');
      final matchRes = await http.get(matchUri, headers: {'Accept': 'application/json'});
      if (matchRes.statusCode == 200) {
        final Map<String, dynamic> payload = json.decode(matchRes.body) as Map<String, dynamic>;
        final matched = payload['matched'] == true;
        if (matched) {
          final matchReq = payload['match_request'] as Map<String, dynamic>;
          final matchedTeacher = payload['matched_teacher'] as Map<String, dynamic>?;
          final transferMatch = payload['transfer_match'] as Map<String, dynamic>?;
          _showMatchDialog(requestId, matchReq, matchedTeacher, transferMatch);
        } else {
          _showNoMatchDialog(requestId);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request submitted: $requestId (match check failed)')),
          );
        }
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.12,
        ),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isPosting = false;
            Future<void> withPosting(Future<void> Function() run) async {
              setStateDialog(() => isPosting = true);
              try {
                await run();
              } finally {
                setStateDialog(() => isPosting = false);
              }
            }
            return Stack(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.76,
                    maxWidth: screenWidth * 0.84,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with success indicator
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.done_all, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Transfer Match Found!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Match summary in compact grid
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Match Details',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              
                              // Request IDs row
                              Row(
                                children: [
                                  Expanded(child: _compactInfoTile('Your Request', requestId)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _compactInfoTile('Match Request', matchReq['request_id']?.toString() ?? 'N/A')),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // District transfer
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3251).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  children: [
                                    Text('${matchReq['from_district']} ⇄ ${matchReq['to_district']}',
                                         style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    if (transferMatch != null)
                                      Text('Match ID: ${transferMatch['matching_id']}',
                                           style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Other teacher details (if available)
                        if (matchedTeacher != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3251).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1A3251).withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Other Teacher',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _compactInfoTile('Name', matchedTeacher['teacher_name'])),
                                    const SizedBox(width: 12),
                                    Expanded(child: _compactInfoTile('District', matchedTeacher['current_district'])),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _compactInfoTile('Years', matchedTeacher['years_in_service_district']?.toString())),
                                    const SizedBox(width: 12),
                                    Expanded(child: _compactInfoTile('Phone', matchedTeacher['phone'])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        
                        // Action notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Would you like to proceed with this transfer match?',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ),
                            if (transferMatch != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isPosting
                                      ? null
                                      : () async {
                                          await withPosting(() async {
                                            final matchingId = transferMatch['matching_id']?.toString() ?? '';
                                            final uri = Uri.parse('$_baseUrl/api/transfer-requests/match/$matchingId/disagree?request_id=${Uri.encodeComponent(requestId)}');
                                            final res = await http.post(uri, headers: {'Accept': 'application/json'});
                                            if (res.statusCode == 200) {
                                              if (mounted) Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You disagreed with this match.')));
                                            } else {
                                              _showErrorDialog('Failed to disagree (${res.statusCode}).');
                                            }
                                          });
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(color: Color(0xFFDC2626)),
                                  ),
                                  child: const Text('Disagree'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: isPosting
                                      ? null
                                      : () async {
                                          await withPosting(() async {
                                            final matchingId = transferMatch['matching_id']?.toString() ?? '';
                                            final uri = Uri.parse('$_baseUrl/api/transfer-requests/match/$matchingId/agree?request_id=${Uri.encodeComponent(requestId)}');
                                            final res = await http.post(uri, headers: {'Accept': 'application/json'});
                                            if (res.statusCode == 200) {
                                              final Map<String, dynamic> m = json.decode(res.body) as Map<String, dynamic>;
                                              final status = (m['match_status'] ?? '').toString();
                                              if (mounted) Navigator.of(context).pop();
                                              final msg = status == 'AGREED'
                                                  ? 'Both teachers agreed. Admin will be notified.'
                                                  : 'Your agreement is recorded. Waiting for the other teacher.';
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                            } else {
                                              _showErrorDialog('Failed to approve transfer (${res.statusCode}).');
                                            }
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('I Agree'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isPosting)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showNoMatchDialog(String requestId) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.12,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.76,
            maxWidth: screenWidth * 0.84,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with status
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 30,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title and message
              const Text(
                'No Exact Match Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No matching transfer found right now. Add to waiting list to be notified when a match becomes available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final uri = Uri.parse('$_baseUrl/api/transfer-requests/$requestId/waiting-list');
                        try {
                          final res = await http.post(uri, headers: {'Accept': 'application/json'});
                          if (res.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to waiting list: $requestId'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          } else {
                            _showErrorDialog('Failed to add to waiting list (${res.statusCode}).');
                          }
                        } catch (_) {
                          _showErrorDialog('Network error adding to waiting list.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3251),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add to Waiting List'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.12,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.76,
            maxWidth: screenWidth * 0.84,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 30,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title and message
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              
              // OK button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
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
