import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/govease_header.dart';
import 'auth_screen.dart';

class ZonalAdminDashboardScreen extends StatefulWidget {
  final String? adminId;
  const ZonalAdminDashboardScreen({super.key, this.adminId});

  @override
  State<ZonalAdminDashboardScreen> createState() =>
      _ZonalAdminDashboardScreenState();
}

class _ZonalAdminDashboardScreenState extends State<ZonalAdminDashboardScreen> {
  final String _baseUrl = 'http://localhost:8000';

  List<String> _controllingZones = [];
  String? _selectedZone; // for matches
  String? _selectedDistrict; // for analytics

  bool _loadingMatches = false;
  bool _loadingFlow = false;
  List<dynamic> _matches = [];
  Map<String, dynamic>? _flow;
  Map<String, dynamic>? _admin;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const GovEaseHeader(
                height: 220,
                subtitle: 'Administration',
                sectionTitle: 'Zonal Admin Dashboard',
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_admin != null)
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1976D2,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF1976D2),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Controlling Districts',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final z in List<String>.from(
                                              (_admin!['controlling_zones'] ??
                                                      [])
                                                  as List,
                                            ))
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF1976D2),
                                                      const Color(0xFF42A5F5),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  z,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Analytics Overview Cards
                      _buildAnalyticsOverview(),

                      // Transfer Matches Section
                      _buildTransferMatchesSection(),

                      // District Flow Section
                      _buildDistrictFlowSection(),

                      const SizedBox(height: 80), // Space for floating button
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildAnalyticsOverview() {
    if (_admin == null) return const SizedBox.shrink();

    final controllingZones = List<String>.from(
      (_admin!['controlling_zones'] ?? []) as List,
    );
    final totalMatches = _matches.length;
    final agreedMatches = _matches
        .where((m) => m['match_status'] == 'AGREED')
        .length;
    final pendingMatches = totalMatches - agreedMatches;

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistics Cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12, // Reduced spacing
            mainAxisSpacing: 12, // Reduced spacing
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio:
                1.8, // Increased aspect ratio to make cards shorter
            children: [
              _buildStatCard(
                'Total Districts',
                controllingZones.length.toString(),
                Icons.location_city,
                const Color(0xFF1976D2),
              ),
              _buildStatCard(
                'Total Matches',
                totalMatches.toString(),
                Icons.swap_horiz,
                const Color(0xFF9C27B0),
              ),
              _buildStatCard(
                'Agreed Matches',
                agreedMatches.toString(),
                Icons.check_circle,
                const Color(0xFF4CAF50),
              ),
              _buildStatCard(
                'Pending Matches',
                pendingMatches.toString(),
                Icons.pending,
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Add this
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Reduced padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24), // Reduced size
          ),
          const SizedBox(height: 8), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 20, // Reduced font size
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            title,
            style: TextStyle(
              fontSize: 12, // Reduced font size
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Add max lines
            overflow: TextOverflow.ellipsis, // Add overflow handling
          ),
        ],
      ),
    );
  }

  Widget _buildTransferMatchesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: Color(0xFF2196F3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Transfer Matches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_controllingZones.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No controlling districts assigned.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value:
                          _selectedZone ??
                          (_controllingZones.isNotEmpty
                              ? _controllingZones.first
                              : null),
                      items: _controllingZones
                          .map(
                            (z) => DropdownMenuItem<String>(
                              value: z,
                              child: Text(z),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedZone = v),
                      decoration: const InputDecoration(
                        labelText: 'Select District',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadingMatches ? null : _loadMatches,
                    icon: _loadingMatches
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Load'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEnhancedMatchesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDistrictFlowSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFFE91E63),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'District Flow Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_controllingZones.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value:
                          _selectedDistrict ??
                          (_controllingZones.isNotEmpty
                              ? _controllingZones.first
                              : null),
                      items: _controllingZones
                          .map(
                            (z) => DropdownMenuItem<String>(
                              value: z,
                              child: Text(z),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v),
                      decoration: const InputDecoration(
                        labelText: 'Select District',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadingFlow ? null : _loadFlow,
                    icon: _loadingFlow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEnhancedFlowStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedMatchesList() {
    if (_loadingMatches) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading matches...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No matches found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try selecting a different district or check back later.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        final m = _matches[i] as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Match ${m['matching_id']?.toString() ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  _statusChip(m['match_status']?.toString()),
                ],
              ),
              const SizedBox(height: 16),
              _enhancedMatchRequestRow(
                'Request A',
                m['request_a'] as Map<String, dynamic>?,
              ),
              const SizedBox(height: 12),
              _enhancedMatchRequestRow(
                'Request B',
                m['request_b'] as Map<String, dynamic>?,
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _matches.length,
    );
  }

  Widget _enhancedMatchRequestRow(String label, Map<String, dynamic>? r) {
    if (r == null) return const SizedBox.shrink();
    final t = (r['teacher'] ?? {}) as Map<String, dynamic>;
    final subjects = (t['subjects'] as List?)?.join(', ') ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${r['from_district']} → ${r['to_district']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t['teacher_name'] ?? 'Unknown Teacher',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.school, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(child: Text('School: ${t['school_id'] ?? 'N/A'}')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.book, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(child: Text('Subjects: $subjects')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Experience: ${t['years_in_service_district'] ?? 'N/A'} years',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFlowStats() {
    if (_loadingFlow) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Analyzing flow data...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_flow == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No analytics data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final incoming = Map<String, dynamic>.from(_flow!['incoming'] as Map);
    final outgoing = Map<String, dynamic>.from(_flow!['outgoing'] as Map);
    final totals = Map<String, dynamic>.from(_flow!['totals'] as Map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flow Summary Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totals['incoming']?.toString() ?? '0',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Incoming',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totals['outgoing']?.toString() ?? '0',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Outgoing',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Detailed Breakdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Incoming Districts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 12),
              _enhancedFlowList(incoming, const Color(0xFF4CAF50)),
              const SizedBox(height: 20),
              const Text(
                'Top Outgoing Districts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 12),
              _enhancedFlowList(outgoing, const Color(0xFFFF9800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _enhancedFlowList(Map<String, dynamic> data, Color color) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final maxVal = entries.isEmpty ? 1 : (entries.first.value as int);

    return Column(
      children: [
        for (final e in entries.take(5))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: maxVal == 0 ? 0 : (e.value as int) / maxVal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${e.value}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _loadMatches() async {
    setState(() => _loadingMatches = true);
    try {
      final zone =
          _selectedZone ??
          (_controllingZones.isNotEmpty ? _controllingZones.first : null);
      if (zone == null) {
        _snack('No district selected');
        return;
      }
      final uri = Uri.parse(
        '$_baseUrl/api/admin-analytics/matches?zones=${Uri.encodeComponent(zone)}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        setState(() => _matches = (data['items'] as List?) ?? []);
      } else {
        _snack('Failed to load matches (${res.statusCode}).');
      }
    } catch (_) {
      _snack('Network error loading matches');
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  Future<void> _loadFlow() async {
    setState(() => _loadingFlow = true);
    try {
      final district =
          _selectedDistrict ??
          (_controllingZones.isNotEmpty ? _controllingZones.first : null);
      if (district == null) {
        _snack('Enter a district');
        return;
      }
      final uri = Uri.parse(
        '$_baseUrl/api/admin-analytics/district-flow/${Uri.encodeComponent(district)}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
        setState(() => _flow = data);
      } else {
        _snack('Failed to load analytics (${res.statusCode}).');
      }
    } catch (_) {
      _snack('Network error loading analytics');
    } finally {
      if (mounted) setState(() => _loadingFlow = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadAdmin() async {
    final id = widget.adminId;
    if (id == null || id.isEmpty) return;
    try {
      final uri = Uri.parse('$_baseUrl/api/admins/${Uri.encodeComponent(id)}');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final zones =
            (data['controlling_zones'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        setState(() {
          _admin = data;
          _controllingZones = zones;
          _selectedZone = zones.isNotEmpty ? zones.first : null;
          _selectedDistrict = zones.isNotEmpty ? zones.first : null;
        });
      }
    } catch (_) {}
  }

  Widget _statusChip(String? status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'AGREED':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'PENDING_AGREED':
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF5B21B6);
        break;
      default:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF075985);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        status ?? 'PENDING',
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
