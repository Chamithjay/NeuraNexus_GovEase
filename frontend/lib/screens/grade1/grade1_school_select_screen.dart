import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'grade1_application_form_screen.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const SchoolDetailsScreen({
    Key? key,
    required this.schoolId,
    required this.schoolName,
  }) : super(key: key);

  @override
  _SchoolDetailsScreenState createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen> {
  Map<String, dynamic>? schoolDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchoolDetails();
  }

Future<void> _fetchSchoolDetails() async {
  try {
    // Replace with Google Places Details API
    final placeId = widget.schoolId; // Pass the Google Place ID from previous search
    final apiKey = 'AIzaSyCesCVYM6Gc8gQYPODvd70WZYAGYBu38QY'; // Put your key here
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number,website,geometry,types&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];

      setState(() {
        schoolDetails = {
          'name': result['name'] ?? widget.schoolName,
          'id': placeId,
          'type': (result['types'] != null && result['types'].isNotEmpty)
              ? result['types'][0]
              : 'School',
          'medium': 'N/A', // Google API does not provide medium
          'grades': 'N/A', // Add manually or from static
          'established': 'N/A', // Add manually
          'address': result['formatted_address'] ?? 'N/A',
          'contact_number': result['formatted_phone_number'] ?? 'N/A',
          'email': 'N/A', // Google API rarely gives email
          'principal': 'N/A', // Needs manual input
          'vice_principal': 'N/A', // Needs manual input
          'image_url': 'assets/images/school_placeholder.jpg',
          'admission_info': {
            'grade': 'Grade 1',
            'period': '1st June - 30th June (Every Year)',
          },
          'latitude': result['geometry'] != null
              ? result['geometry']['location']['lat']
              : null,
          'longitude': result['geometry'] != null
              ? result['geometry']['location']['lng']
              : null,
          'website': result['website'] ?? 'N/A',
        };
        isLoading = false;
      });
    } else {
      throw Exception('Failed to fetch school details');
    }
  } catch (e) {
    // Fallback to static data if API fails
    setState(() {
      schoolDetails = _getStaticSchoolDetails();
      isLoading = false;
    });
  }
}

  Map<String, dynamic> _getStaticSchoolDetails() {
    // Static data as fallback
    return {
      'name': widget.schoolName,
      'id': 'SCH-1023',
      'type': 'Government Primary School',
      'medium': 'Sinhala',
      'grades': '1-5',
      'established': '1962',
      'address': 'No. 45, Sudarshana Mawatha, Kandy',
      'contact_number': '+94 11 2 345 678',
      'email': 'info@sudarshana.lk',
      'principal': 'Mrs. K. Perera',
      'vice_principal': 'Mr. D. Silva',
      'image_url': 'assets/images/school_placeholder.jpeg',
      'admission_info': {
        'grade': 'Grade 1',
        'period': '1st June - 30th June (Every Year)',
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3F51B5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'GovEase',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF3F51B5)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Section
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          'Educational Services',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Grade 1 Admission',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // School Name
                  Text(
                    schoolDetails!['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // School Image
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: schoolDetails!['image_url'] != null
                          ? Image.network(
                              schoolDetails!['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // School Details
                  _buildDetailsList(),
                  
                  SizedBox(height: 20),

                  // Admission Information
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admission Information (${schoolDetails!['admission_info']['grade']})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Admission Period: ${schoolDetails!['admission_info']['period']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplicationFormScreen(
                                  schoolName: schoolDetails!['name'],
                                  schoolId: schoolDetails!['id'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3F51B5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply for This School',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF3F51B5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Go Back to Schools',
                            style: TextStyle(
                              color: Color(0xFF3F51B5),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'School Image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList() {
    final details = [
      {'label': 'School Name:', 'value': schoolDetails!['name']},
      {'label': 'School ID:', 'value': schoolDetails!['id']},
      {'label': 'Type:', 'value': schoolDetails!['type']},
      {'label': 'Medium:', 'value': schoolDetails!['medium']},
      {'label': 'Grades:', 'value': schoolDetails!['grades']},
      {'label': 'Established:', 'value': schoolDetails!['established']},
      {'label': 'Address:', 'value': schoolDetails!['address']},
      {'label': 'Contact Number:', 'value': schoolDetails!['contact_number']},
      {'label': 'Email:', 'value': schoolDetails!['email']},
      {'label': 'Principal:', 'value': schoolDetails!['principal']},
      {'label': 'Vice Principal:', 'value': schoolDetails!['vice_principal']},
    ];

    return Column(
      children: details.map((detail) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF3F51B5),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: detail['label'],
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${detail['value']}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}