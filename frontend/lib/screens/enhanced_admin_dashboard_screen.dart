import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../widgets/govease_header.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String _baseUrl = 'http://localhost:8000';

  // Admin type selection
  String _selectedAdminType = 'Zonal Admin';
  final List<String> _adminTypes = ['Zonal Admin', 'School Admin'];

  // Zonal Admin fields
  final _zonesController = TextEditingController(text: 'Kandy');
  final _districtController = TextEditingController(text: 'Kandy');

  // School Admin fields
  final _schoolIdController = TextEditingController(text: 'SCH001');

  bool _loadingMatches = false;
  bool _loadingFlow = false;
  bool _loadingSchoolStats = false;
  List<dynamic> _matches = [];
  Map<String, dynamic>? _flow;
  Map<String, dynamic>? _schoolStats;

  @override
  void dispose() {
    _zonesController.dispose();
    _districtController.dispose();
    _schoolIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GovEaseHeader(
              height: 220,
              subtitle: 'Administration',
              sectionTitle: 'Admin Dashboard',
              onBack: () => Navigator.pop(context),
              onNotifications: null,
            ),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Type Selection
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Admin Type',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedAdminType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _adminTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAdminType = value!;
                                // Clear data when switching types
                                _matches.clear();
                                _flow = null;
                                _schoolStats = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Conditional content based on admin type
                  if (_selectedAdminType == 'Zonal Admin') ...[
                    _buildZonalAdminDashboard(),
                  ] else ...[
                    _buildSchoolAdminDashboard(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF4F6F9),
    );
  }

  Widget _buildZonalAdminDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Actions Section
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3251), Color(0xFF2B4A6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Zonal Administration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.swap_horiz,
                        title: 'Transfer Matches',
                        subtitle: 'View and manage transfers',
                        color: const Color(0xFF059669),
                        onTap: () => _showTransferMatchesSection(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.analytics,
                        title: 'District Analytics',
                        subtitle: 'Flow and statistics',
                        color: const Color(0xFF7C3AED),
                        onTap: () => _showDistrictFlowSection(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Transfer Matches Section
        if (_showTransferMatches) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz, color: Color(0xFF059669)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Transfer Matches Management',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showTransferMatches = false),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _zonesController,
                          decoration: InputDecoration(
                            labelText: 'Zones (comma-separated)',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _loadingMatches ? null : _loadMatches,
                        icon: _loadingMatches
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Icon(Icons.search),
                        label: Text(_loadingMatches ? 'Loading...' : 'Load Matches'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMatchesList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // District Flow Analytics Section
        if (_showDistrictFlow) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'District Flow Analytics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showDistrictFlow = false),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _districtController,
                          decoration: InputDecoration(
                            labelText: 'District Name',
                            prefixIcon: const Icon(Icons.place),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _loadingFlow ? null : _loadFlow,
                        icon: _loadingFlow
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Icon(Icons.bar_chart),
                        label: Text(_loadingFlow ? 'Loading...' : 'Load Analytics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFlowStats(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  bool _showTransferMatches = false;
  bool _showDistrictFlow = false;

  void _showTransferMatchesSection() {
    setState(() {
      _showTransferMatches = true;
      _showDistrictFlow = false;
    });
  }

  void _showDistrictFlowSection() {
    setState(() {
      _showDistrictFlow = true;
      _showTransferMatches = false;
    });
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolAdminDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School Selection
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'School Applications Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _schoolIdController,
                        decoration: const InputDecoration(
                          labelText: 'School ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadingSchoolStats ? null : _loadSchoolStats,
                      child: _loadingSchoolStats
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Load'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Grade Statistics
        if (_schoolStats != null) _buildSchoolStatsSection(),
      ],
    );
  }

  Widget _buildSchoolStatsSection() {
    final gradeStats = Map<String, dynamic>.from(_schoolStats!['grade_stats'] as Map? ?? {});
    
    return Column(
      children: [
        // Overview Cards
        _buildOverviewCards(gradeStats),
        const SizedBox(height: 20),

        // Grade 1 Section
        _buildGradeSection('Grade 1', gradeStats['Grade 1'] as Map<String, dynamic>?, Colors.blue),
        const SizedBox(height: 16),

        // Grade 5 Section
        _buildGradeSection('Grade 5', gradeStats['Grade 5'] as Map<String, dynamic>?, Colors.green),
        const SizedBox(height: 16),

        // A/L Section
        _buildGradeSection('A/L', gradeStats['A/L'] as Map<String, dynamic>?, Colors.orange),
      ],
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> gradeStats) {
    int totalApplications = 0;
    int totalApproved = 0;
    int totalPending = 0;

    for (final grade in gradeStats.values) {
      final gradeData = grade as Map<String, dynamic>;
      totalApplications += (gradeData['total'] as int? ?? 0);
      final byStatus = gradeData['by_status'] as Map<String, dynamic>? ?? {};
      totalApproved += (byStatus['Approved'] as int? ?? 0);
      totalPending += (byStatus['Pending'] as int? ?? 0);
    }

    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Applications', totalApplications.toString(), Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Approved', totalApproved.toString(), Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Pending', totalPending.toString(), Colors.orange)),
      ],
    );
  }

  Widget _buildGradeSection(String grade, Map<String, dynamic>? gradeData, Color color) {
    if (gradeData == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(grade, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 8),
              const Text('No applications yet'),
            ],
          ),
        ),
      );
    }

    final total = gradeData['total'] as int? ?? 0;
    final byStatus = Map<String, dynamic>.from(gradeData['by_status'] as Map? ?? {});
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(grade, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: $total',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status breakdown with pie chart
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 150,
                    child: total > 0 ? PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(byStatus, color),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ) : const Center(child: Text('No data')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in byStatus.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(entry.key, color),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> byStatus, Color baseColor) {
    final total = byStatus.values.fold(0, (sum, count) => sum + (count as int));
    if (total == 0) return [];

    return byStatus.entries.map((entry) {
      final count = entry.value as int;
      final percentage = (count / total) * 100;
      return PieChartSectionData(
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getStatusColor(entry.key, baseColor),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Color _getStatusColor(String status, Color baseColor) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Waiting List':
        return Colors.orange;
      default: // Pending
        return baseColor;
    }
  }

  Widget _buildMatchesList() {
    if (_loadingMatches) {
      return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
    }
    if (_matches.isEmpty) {
      return const Text('No matches to display.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        final m = _matches[i] as Map<String, dynamic>;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m['matching_id']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _statusChip(m['match_status']?.toString()),
                  ],
                ),
                const SizedBox(height: 8),
                _matchRequestRow('A', m['request_a'] as Map<String, dynamic>?),
                const SizedBox(height: 8),
                _matchRequestRow('B', m['request_b'] as Map<String, dynamic>?),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _matches.length,
    );
  }

  Widget _matchRequestRow(String label, Map<String, dynamic>? r) {
    if (r == null) return const SizedBox.shrink();
    final t = (r['teacher'] ?? {}) as Map<String, dynamic>;
    final subjects = (t['subjects'] as List?)?.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('Request $label'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r['from_district']} -> ${r['to_district']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Teacher: ${t['teacher_name'] ?? '-'} (${t['current_district'] ?? '-'})'),
              Text('Subjects: ${subjects ?? '-'}'),
              Text('Years in district: ${t['years_in_service_district'] ?? '-'} | School: ${t['school_id'] ?? '-'}'),
            ],
          ),
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status ?? 'PENDING', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFlowStats() {
    if (_loadingFlow) {
      return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
    }
    if (_flow == null) {
      return const Text('No analytics to display.');
    }
    final incoming = Map<String, dynamic>.from(_flow!['incoming'] as Map);
    final outgoing = Map<String, dynamic>.from(_flow!['outgoing'] as Map);
    final totals = Map<String, dynamic>.from(_flow!['totals'] as Map);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary metrics
        Row(
          children: [
            Expanded(child: _buildMetricCard('Incoming', totals['incoming']?.toString() ?? '0', const Color(0xFF0EA5E9))),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Outgoing', totals['outgoing']?.toString() ?? '0', const Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 20),
        
        // Bar charts
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Incoming Requests', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _buildBarChart(incoming, const Color(0xFF0EA5E9)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outgoing Requests', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _buildBarChart(outgoing, const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data, Color color) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final maxVal = entries.isEmpty ? 1 : (entries.first.value as int);

    return BarChart(
      BarChartData(
        maxY: maxVal.toDouble(),
        barGroups: entries.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final dataEntry = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (dataEntry.value as int).toDouble(),
                color: color,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        entries[index].key,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _loadMatches() async {
    setState(() => _loadingMatches = true);
    try {
      final zones = _zonesController.text.trim();
      final uri = Uri.parse('$_baseUrl/api/admin-analytics/matches${zones.isNotEmpty ? '?zones=${Uri.encodeComponent(zones)}' : ''}');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _matches = (data['items'] as List?) ?? []);
      } else {
        _showSnack('Failed to load matches (${res.statusCode}).');
      }
    } catch (_) {
      _showSnack('Network error loading matches');
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  Future<void> _loadFlow() async {
    setState(() => _loadingFlow = true);
    try {
      final district = _districtController.text.trim();
      if (district.isEmpty) {
        _showSnack('Enter a district');
        return;
      }
      final uri = Uri.parse('$_baseUrl/api/admin-analytics/district-flow/${Uri.encodeComponent(district)}');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _flow = data);
      } else {
        _showSnack('Failed to load analytics (${res.statusCode}).');
      }
    } catch (_) {
      _showSnack('Network error loading analytics');
    } finally {
      if (mounted) setState(() => _loadingFlow = false);
    }
  }

  Future<void> _loadSchoolStats() async {
    setState(() => _loadingSchoolStats = true);
    try {
      final schoolId = _schoolIdController.text.trim();
      if (schoolId.isEmpty) {
        _showSnack('Enter a school ID');
        return;
      }
      final uri = Uri.parse('$_baseUrl/api/demo/school-stats/$schoolId');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _schoolStats = data);
      } else {
        _showSnack('Failed to load school stats (${res.statusCode}).');
      }
    } catch (_) {
      _showSnack('Network error loading school stats');
    } finally {
      if (mounted) setState(() => _loadingSchoolStats = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
