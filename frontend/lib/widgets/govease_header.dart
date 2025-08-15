import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GovEaseHeader extends StatefulWidget {
  final double height;
  final String subtitle; // e.g., Educational Services
  final String sectionTitle; // e.g., Teacher Transfers
  final VoidCallback? onBack;
  final VoidCallback? onNotifications;
  final bool enableNotifications; // if true and citizenId provided, show unread badge
  final String baseUrl; // backend base URL
  final String? citizenId; // logged-in citizen id

  const GovEaseHeader({
    super.key,
    this.height = 220,
    this.subtitle = '',
    this.sectionTitle = '',
    this.onBack,
    this.onNotifications,
    this.enableNotifications = false,
    this.baseUrl = 'http://localhost:8000',
    this.citizenId,
  });

  @override
  State<GovEaseHeader> createState() => _GovEaseHeaderState();
}

class _GovEaseHeaderState extends State<GovEaseHeader> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (!widget.enableNotifications || (widget.citizenId == null || widget.citizenId!.isEmpty)) return;
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/notifications/citizen/${Uri.encodeComponent(widget.citizenId!)}?only_unread=true');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        if (mounted) setState(() => _unread = list.length);
      }
    } catch (_) {
      // ignore network error for header badge
    } finally {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
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
            if (widget.onBack != null)
              Positioned(
                left: 16,
                top: 10,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            if (widget.onNotifications != null || widget.enableNotifications)
              Positioned(
                right: 16,
                top: 10,
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: widget.onNotifications,
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                    ),
                    if (widget.enableNotifications && _unread > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            _unread > 99 ? '99+' : '$_unread',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 60,
              child: Column(
                children: [
                  const Text(
                    'GovEase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.subtitle.isNotEmpty)
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.sectionTitle.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.sectionTitle,
                      style: const TextStyle(
                        color: Color(0xFF0E2B51),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
