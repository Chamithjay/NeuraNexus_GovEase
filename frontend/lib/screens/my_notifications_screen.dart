import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyNotificationsScreen extends StatefulWidget {
  final String citizenId;
  final String baseUrl;
  const MyNotificationsScreen({super.key, required this.citizenId, required this.baseUrl});

  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  bool _loading = true;
  List<dynamic> _items = [];
  // Per-notification action loading state (agree/disagree)
  final Map<String, bool> _actionLoading = {};
  // Global overlay loader during actions for better UX
  bool _globalActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/notifications/citizen/${Uri.encodeComponent(widget.citizenId)}');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body) as List<dynamic>;
        setState(() => _items = list);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load (${res.statusCode})')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error loading notifications')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/notifications/citizen/${Uri.encodeComponent(widget.citizenId)}/read-all');
      final res = await http.post(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _fetch();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Gradient header like others
          Container(
            width: double.infinity,
            height: 180,
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
                    left: 16,
                    top: 12,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 70,
                    child: Center(
                      child: Text(
                        'My Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
              Expanded(
                child: RefreshIndicator(
                    onRefresh: _fetch,
                    child: _items.isEmpty
                        ? const Center(child: Text('No notifications'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final n = _items[index] as Map<String, dynamic>;
                              final isRead = n['is_read'] == true;
                              final type = (n['type'] ?? '').toString();
                              final id = (n['notification_id'] ?? '').toString();
                              final desc = (n['description'] ?? '').toString();
                              final ts = (n['created_at'] ?? '').toString();
                              final matchingId = (n['matching_id'] ?? '').toString();
                              final requestId = (n['request_id'] ?? '').toString();
                              final actionable = type == 'TRANSFER' && matchingId.isNotEmpty && requestId.isNotEmpty;
                              final isActLoading = _actionLoading[id] == true;
                              return Container(
                                decoration: BoxDecoration(
                                  color: isRead ? const Color(0xFFF3F4F6) : Colors.white,
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(desc, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('$type • $ts', style: const TextStyle(color: Colors.black54)),
                                      if (actionable && !isRead) ...[
                                        const SizedBox(height: 8),
                                        if (isActLoading)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: 10),
                                                Text('Processing...', style: TextStyle(color: Colors.black54)),
                                              ],
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  setState(() {
                                                    _actionLoading[id] = true;
                                                    _globalActionLoading = true;
                                                  });
                                                  try {
                                                    final uri = Uri.parse('${widget.baseUrl}/api/transfer-requests/match/$matchingId/agree?request_id=${Uri.encodeComponent(requestId)}');
                                                    final res = await http.post(uri, headers: {'Accept': 'application/json'});
                                                    if (res.statusCode == 200) {
                                                      // Mark notification as read after successful action
                                                      try {
                                                        final readUri = Uri.parse('${widget.baseUrl}/api/notifications/citizen/${Uri.encodeComponent(widget.citizenId)}/read/${Uri.encodeComponent(id)}');
                                                        await http.post(readUri, headers: {'Accept': 'application/json'});
                                                      } catch (_) {}
                                                      if (mounted) {
                                                        // update local state to hide action buttons immediately
                                                        final idx = _items.indexWhere((e) => (e as Map<String, dynamic>)['notification_id'] == id);
                                                        if (idx != -1) {
                                                          (_items[idx] as Map<String, dynamic>)['is_read'] = true;
                                                        }
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreed to transfer match.')));
                                                      }
                                                    } else {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed (${res.statusCode})')));
                                                      }
                                                    }
                                                  } catch (_) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
                                                    }
                                                  } finally {
                                                    if (mounted) setState(() {
                                                      _actionLoading[id] = false;
                                                      _globalActionLoading = false;
                                                    });
                                                  }
                                                },
                                                icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.white),
                                                label: const Text('Agree', style: TextStyle(color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1A3251),
                                                  foregroundColor: Colors.white,
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              OutlinedButton.icon(
                                                onPressed: () async {
                                                  setState(() {
                                                    _actionLoading[id] = true;
                                                    _globalActionLoading = true;
                                                  });
                                                  try {
                                                    final uri = Uri.parse('${widget.baseUrl}/api/transfer-requests/match/$matchingId/disagree?request_id=${Uri.encodeComponent(requestId)}');
                                                    final res = await http.post(uri, headers: {'Accept': 'application/json'});
                                                    if (res.statusCode == 200) {
                                                      // Mark notification as read after successful action
                                                      try {
                                                        final readUri = Uri.parse('${widget.baseUrl}/api/notifications/citizen/${Uri.encodeComponent(widget.citizenId)}/read/${Uri.encodeComponent(id)}');
                                                        await http.post(readUri, headers: {'Accept': 'application/json'});
                                                      } catch (_) {}
                                                      if (mounted) {
                                                        final idx = _items.indexWhere((e) => (e as Map<String, dynamic>)['notification_id'] == id);
                                                        if (idx != -1) {
                                                          (_items[idx] as Map<String, dynamic>)['is_read'] = true;
                                                        }
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disagreed. Match reset to pending.')));
                                                      }
                                                    } else {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed (${res.statusCode})')));
                                                      }
                                                    }
                                                  } catch (_) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
                                                    }
                                                  } finally {
                                                    if (mounted) setState(() {
                                                      _actionLoading[id] = false;
                                                      _globalActionLoading = false;
                                                    });
                                                  }
                                                },
                                                icon: const Icon(Icons.thumb_down_alt_outlined, color: Color(0xFF1A3251)),
                                                label: const Text('Disagree', style: TextStyle(color: Color(0xFF1A3251))),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFF1A3251)),
                                                  foregroundColor: const Color(0xFF1A3251),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: isRead
                                            ? const Icon(Icons.done_all, color: Colors.green)
                                            : TextButton(
                                                onPressed: () async {
                                                  try {
                                                    final uri = Uri.parse('${widget.baseUrl}/api/notifications/citizen/${Uri.encodeComponent(widget.citizenId)}/read/${Uri.encodeComponent(id)}');
                                                    final res = await http.post(uri, headers: {'Accept': 'application/json'});
                                                    if (res.statusCode == 200) _fetch();
                                                  } catch (_) {}
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(0xFF1A3251),
                                                ),
                                                child: const Text('Mark read'),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_globalActionLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _markAllRead,
        label: const Text('Mark all read', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.mark_email_read_outlined, color: Colors.white),
        backgroundColor: const Color(0xFF1A3251),
      ),
    );
  }
}
