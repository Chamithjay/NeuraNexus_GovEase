import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/govease_header.dart';
import 'home_screen.dart';
import 'zonal_admin_dashboard_screen.dart';
import 'school_admin_dashboard_screen.dart';
import 'citizen_register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final String _baseUrl = 'http://localhost:8000';

  final _loginFormKey = GlobalKey<FormState>();

  // Shared
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Register only

  final bool _isLogin = true; // deprecated toggle, always keep login view
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  height: 240,
                  subtitle: 'Welcome to GovEase',
                  sectionTitle: _isLogin ? 'Login' : 'Register',
                  onBack: null,
                  onNotifications: null,
                ),
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLoginForm(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CitizenRegisterScreen(baseUrl: _baseUrl),
                              ),
                            );
                          },
                          child: const Text('Register as Citizen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            'Email',
            'you@example.com',
            _emailController,
            validator: _emailValidator,
          ),
          const SizedBox(height: 12),
          _field(
            'Password',
            '••••••••',
            _passwordController,
            obscure: true,
            validator: _passwordValidator,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3251),
                foregroundColor: Colors.white,
              ),
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    if (!v.contains('@')) return 'Invalid email';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.trim().length < 6) return 'Min 6 characters';
    return null;
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController c, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>?;
        final role = user?['role']?.toString() ?? 'Citizen';
        final citizenId = user?['linked_citizen_id']?.toString();
        final adminId = user?['linked_admin_id']?.toString();
        _routeByRole(role, citizenId: citizenId, adminId: adminId);
      } else {
        _snack('Login failed (${res.statusCode})');
      }
    } catch (_) {
      _snack('Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _routeByRole(String role, {String? citizenId, String? adminId}) {
    Widget screen;
    switch (role) {
      case 'ZonalAdmin':
        screen = ZonalAdminDashboardScreen(adminId: adminId);
        break;
      case 'SchoolAdmin':
        screen = const SchoolAdminDashboardScreen();
        break;
      default:
        screen = HomeScreen(citizenId: citizenId);
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
