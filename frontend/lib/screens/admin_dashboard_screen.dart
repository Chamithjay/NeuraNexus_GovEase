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
  final String _selectedAdminType = 'Zonal Admin';
  final List<String> _adminTypes = ['Zonal Admin', 'School Admin'];

  // Zonal Admin fields
  final _zonesController = TextEditingController(text: 'Kandy');
  final _districtController = TextEditingController(text: 'Kandy');

  // School Admin fields
  final _schoolIdController = TextEditingController(text: 'SCH001');

  bool _loadingMatches = false;
  bool _loadingFlow = false;
  final bool _loadingSchoolStats = false;
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                GovEaseHeader(
                  height: 220,
                  subtitle: 'Administration',
                  sectionTitle: 'Zonal Admin Dashboard',
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
                      const Text(
                        'Transfer Matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _zonesController,
                              decoration: const InputDecoration(
                                labelText: 'Zones (comma-separated)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _loadingMatches ? null : _loadMatches,
                            child: _loadingMatches
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Load'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMatchesList(),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'District Flow Analytics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _districtController,
                              decoration: const InputDecoration(
                                labelText: 'District',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _loadingFlow ? null : _loadFlow,
                            child: _loadingFlow
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Load'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFlowStats(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
    );
  }

  Widget _buildMatchesList() {
    if (_loadingMatches) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
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
              Text(
                '${r['from_district']} -> ${r['to_district']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Teacher: ${t['teacher_name'] ?? '-'} (${t['current_district'] ?? '-'})',
              ),
              Text('Subjects: ${subjects ?? '-'}'),
              Text(
                'Years in district: ${t['years_in_service_district'] ?? '-'} | School: ${t['school_id'] ?? '-'}',
              ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status ?? 'PENDING',
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFlowStats() {
    if (_loadingFlow) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricCard(
              'Incoming',
              totals['incoming']?.toString() ?? '0',
              const Color(0xFF0EA5E9),
            ),
            _metricCard(
              'Outgoing',
              totals['outgoing']?.toString() ?? '0',
              const Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Top Incoming By From District',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _kvList(incoming),
        const SizedBox(height: 12),
        const Text(
          'Top Outgoing By To District',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _kvList(outgoing),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvList(Map<String, dynamic> m) {
    if (m.isEmpty) return const Text('No data');
    final entries = m.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final maxVal = entries.isEmpty ? 1 : (entries.first.value as int);
    return Column(
      children: [
        for (final e in entries.take(8))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(e.key, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxVal == 0 ? 0 : (e.value as int) / maxVal,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}'),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _loadMatches() async {
    setState(() => _loadingMatches = true);
    try {
      final zones = _zonesController.text.trim();
      final uri = Uri.parse(
        '$_baseUrl/api/admin-analytics/matches${zones.isNotEmpty ? '?zones=${Uri.encodeComponent(zones)}' : ''}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
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
      final uri = Uri.parse(
        '$_baseUrl/api/admin-analytics/district-flow/${Uri.encodeComponent(district)}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(res.body) as Map<String, dynamic>;
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
