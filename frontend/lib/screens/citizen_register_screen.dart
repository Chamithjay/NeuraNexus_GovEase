import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CitizenRegisterScreen extends StatefulWidget {
  final String baseUrl;
  const CitizenRegisterScreen({super.key, required this.baseUrl});

  @override
  State<CitizenRegisterScreen> createState() => _CitizenRegisterScreenState();
}

class _CitizenRegisterScreenState extends State<CitizenRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nic = TextEditingController();
  final _fullName = TextEditingController();
  final _dob = TextEditingController();
  final _gender = ValueNotifier<String>('Male');
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nic.dispose();
    _fullName.dispose();
    _dob.dispose();
    _gender.dispose();
    _address.dispose();
    _contact.dispose();
    _email.dispose();
  _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Registration')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('NIC', '199012345678', _nic, validator: (v) => (v==null||v.isEmpty)?'Required':null),
                  const SizedBox(height: 10),
                  _field('Full Name', 'Amalraj Perera', _fullName, validator: (v) => (v==null||v.isEmpty)?'Required':null),
                  const SizedBox(height: 10),
                  _field('Date of Birth (ISO 8601)', 'YYYY-MM-DDThh:mm:ss.sssZ', _dob, validator: (v)=> (v==null||v.isEmpty)?'Required':null),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: _gender,
                    builder: (context, g, _) => DropdownButtonFormField<String>(
                      value: g,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => _gender.value = v ?? 'Male',
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field('Address', '123 Main Street, Kandy, Sri Lanka', _address, validator: (v)=> (v==null||v.isEmpty)?'Required':null),
                  const SizedBox(height: 10),
                  _field('Contact Number', '+94771234567', _contact, validator: (v)=> (v==null||v.isEmpty)?'Required':null),
                  const SizedBox(height: 10),
                  _field('Email', 'you@example.com', _email, validator: (v)=> (v==null||!v.contains('@'))?'Valid email required':null),
                  const SizedBox(height: 10),
                  _field('Password', 'min 6 characters', _password, validator: (v)=> (v==null||v.length<6)?'Min 6 characters':null, obscure: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: const Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController c, {String? Function(String?)? validator, bool obscure=false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/citizens/');
    final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'nic': _nic.text.trim(),
          'full_name': _fullName.text.trim(),
          'date_of_birth': _dob.text.trim(),
          'gender': _gender.value,
          'address': _address.text.trim(),
          'contact_number': _contact.text.trim(),
          'email': _email.text.trim(),
      'password': _password.text.trim(),
      'citizen_type': 'Citizen'
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Citizen registered')));
        Navigator.of(context).pop();
      } else if (res.statusCode == 400) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final detail = body['detail']?.toString() ?? 'Validation error';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(detail)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed (${res.statusCode})')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
