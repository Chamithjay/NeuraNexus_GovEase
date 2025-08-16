import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class School {
  final String name;
  final String district;
  final List<String> streams;

  School({required this.name, required this.district, required this.streams});

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      name: json['school_name'],
      district: json['district'],
      streams: List<String>.from(json['streams'] ?? []),
    );
  }
}

class SchoolSelectionScreen extends StatefulWidget {
  @override
  _SchoolSelectionScreenState createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  final TextEditingController _districtController = TextEditingController();
  String selectedStream = '';
  String fullName = '';
  String nic = '';
  List<String> files = [];
  List<School> allSchools = [];
  List<School> filteredSchools = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      selectedStream = args['stream'] ?? '';
      fullName = args['fullName'] ?? '';
      nic = args['nic'] ?? '';
      files = List<String>.from(args['files'] ?? []);
      _fetchSchools();
    }
  }

Future<void> _fetchSchools() async {
  try {
    final districtQuery = _districtController.text;
    final url = Uri.parse(
        'http://127.0.0.1:8000/al_schools/search?district=$districtQuery&stream=$selectedStream');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        allSchools = data.map((json) => School.fromJson(json)).toList();
        filteredSchools = allSchools; // show all fetched schools
      });
    } else {
      print('Failed to load schools: ${response.body}');
    }
  } catch (e) {
    print('Error fetching schools: $e');
  }
}

  void _filterSchools() {
    String districtQuery = _districtController.text.toLowerCase();
    setState(() {
      filteredSchools = allSchools.where((school) {
        bool matchesStream = school.streams.contains(selectedStream);
        bool matchesDistrict =
            districtQuery.isEmpty ||
            school.district.toLowerCase().contains(districtQuery);
        return matchesStream && matchesDistrict;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3B4B8C),
      appBar: AppBar(
        backgroundColor: Color(0xFF3B4B8C),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GovEase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4B8C), Color(0xFF4A90E2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Select School for $selectedStream',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    hintText: 'Search by district',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    _fetchSchools(); // call backend on every input change
                  },
                ),

                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSchools.length,
                    itemBuilder: (context, index) {
                      final school = filteredSchools[index];
                      return Card(
                        child: ListTile(
                          title: Text(school.name),
                          subtitle: Text(school.district),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/summary-screen',
                              arguments: {
                                'fullName': fullName,
                                'nic': nic,
                                'stream': selectedStream,
                                'school': school.name,
                                'files': files,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
