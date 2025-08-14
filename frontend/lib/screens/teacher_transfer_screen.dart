import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/govease_header.dart';
import 'my_requests_screen.dart';
import 'my_notifications_screen.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.15,
        ),
        child: Container(
          width: screenWidth * 0.8,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.7,
            maxWidth: screenWidth * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Eligibility banner first
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: eligible ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    border: Border.all(color: eligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(eligible ? Icons.verified : Icons.block,
                          color: eligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          eligible
                              ? 'Eligible for transfer (Years in district: $years)'
                              : 'Ineligible for transfer: requires at least 5 years in district (Current: $years)'.trim(),
                          style: TextStyle(
                            color: eligible ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Teacher Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A3251),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Teacher ID', t['teacher_id']?.toString()),
                      _kv('Name', t['teacher_name']?.toString()),
                      _kv('Current District', t['current_district']?.toString()),
                      _kv('School ID', t['school_id']?.toString()),
                      _kv('Subjects', (t['subjects'] as List?)?.join(', ')),
                      _kv('Years in Service (District)', t['years_in_service_district']?.toString()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3251), Color(0xFF2B4A6B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer Request',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _kvWhite('From District', _currentDistrictController.text),
                      _kvWhite('Applicant Name', _nameController.text),
                      _kvWhite('Reason', _reasonController.text),
                      _kvWhite('Requesting District', _requestingDistrictController.text),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                    if (eligible)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _submitTransferRequest(t);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3251),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Confirm & Submit',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.1,
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
                  width: screenWidth * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.8,
                    maxWidth: screenWidth * 0.9,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8FAFC)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Matching Transfer Found!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Request',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _kv('Request ID', requestId),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Matched Request Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
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
                            ],
                          ),
                        ),
                        if (matchedTeacher != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A3251), Color(0xFF2B4A6B)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Other Teacher Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _kvWhite('Name', matchedTeacher['teacher_name']?.toString()),
                                _kvWhite('Current District', matchedTeacher['current_district']?.toString()),
                                _kvWhite('Years in Service (District)', matchedTeacher['years_in_service_district']?.toString()),
                                _kvWhite('Phone', matchedTeacher['phone']?.toString()),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isPosting ? null : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Close'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (transferMatch != null)
                              Expanded(
                                child: OutlinedButton.icon(
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
                                  icon: const Icon(Icons.thumb_down, size: 18),
                                  label: const Text('Disagree'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(color: Color(0xFFDC2626)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isPosting
                                    ? null
                                    : () async {
                                        await withPosting(() async {
                                          final matchingId = transferMatch != null ? (transferMatch['matching_id']?.toString() ?? '') : '';
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
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('I Agree'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (isPosting)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.15,
        ),
        child: Container(
          width: screenWidth * 0.8,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.7,
            maxWidth: screenWidth * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 40,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Exact Match Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'There is no matching opposite transfer right now. Would you like to add your request to the waiting list?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Add to Waiting List',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.15,
        ),
        child: Container(
          width: screenWidth * 0.8,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.7,
            maxWidth: screenWidth * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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

  Widget _kv(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: (value == null || value.isEmpty) ? 'N/A' : value),
          ],
        ),
      ),
    );
  }

  Widget _kvWhite(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: (value == null || value.isEmpty) ? 'N/A' : value),
          ],
        ),
      ),
    );
  }
}
