import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'grade1_school_select_screen.dart';

class Grade1LocationScreen extends StatefulWidget {
  @override
  _Grade1LocationScreenState createState() => _Grade1LocationScreenState();
}

class _Grade1LocationScreenState extends State<Grade1LocationScreen> {
  late GoogleMapController _mapController;
  bool _showPermissionDialog = true;
  Position? _currentPosition;
  String? _searchQuery = '';
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showPermissionDialog) {
        _showLocationPermissionDialog();
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          12.0,
        ),
      );
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Allow "GovEase" to use\nyour location?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Your precise location is used to show your position on the map, get directions, estimate travel times and improve search results',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFF5F5DC),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Precise: On',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Text(
                          'Current Area',
                          style: TextStyle(fontSize: 10, color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _requestLocationPermission('once');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Allow Once',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _requestLocationPermission('always');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Allow While Using the App',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _showPermissionDialog = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Don\'t Allow',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestLocationPermission(String type) async {
    setState(() {
      _isLoading = true;
    });

    PermissionStatus status = await Permission.location.status;

    if (!status.isGranted) {
      if (type == 'always') {
        status = await Permission.locationAlways.request();
      } else {
        status = await Permission.locationWhenInUse.request();
      }
    }

    if (status.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _updateSchoolsAndMarkers();
        });
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            12.0,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } else {
      setState(() {
        _showPermissionDialog = false;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchSchools(String city) async {
    setState(() {
      _isLoading = true;
      _schools = [];
      _markers.clear();
    });

    // Step 2a: Move map to city
    final cityLatLng = await _getCityLatLng(city);
    if (_mapController != null && cityLatLng != null) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(cityLatLng, 12));
    }

    // Step 2b: Fetch schools from backend
    try {
      final response = await http.get(
        Uri.parse('http://192.168.56.1:8000/schools?city=$city'),
      );
      print('Searching for city: $city');
      print('Schools returned: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          final data = json.decode(response.body);
          _schools = List<Map<String, dynamic>>.from(data['schools']);

          _updateMarkers();
        });
      } else {
        throw Exception('Failed to load schools');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching schools: $e')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<LatLng?> _getCityLatLng(String city) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$city&format=json&limit=1',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lng = double.parse(data[0]['lon']);
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      print('Error fetching city coordinates: $e');
    }
    return null; // fallback if city not found
  }

  void _updateSchoolsAndMarkers() {
    if (_currentPosition != null) {
      // Simulate fetching schools based on current location or search query
      _fetchSchools(
        _searchQuery ?? 'Colombo',
      ); // Default to Colombo if no search
    }
  }

  void _updateMarkers() {
    _markers.clear();

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var school in _schools) {
      final lat = school['latitude'] ?? 0.0;
      final lng = school['longitude'] ?? 0.0;

      _markers.add(
        Marker(
          markerId: MarkerId(school['name']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: school['name'],
            snippet: school['address'],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SchoolDetailsScreen(
                  schoolId: school['id'] ?? 'Unknown',
                  schoolName: school['name'] ?? 'Unknown School',
                ),
              ),
            );
          },
        ),
      );

      // Update bounds for all markers
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    setState(() {});

    // Adjust camera to fit all markers
    if (_markers.isNotEmpty) {
      final southwest = LatLng(minLat, minLng);
      final northeast = LatLng(maxLat, maxLng);
      final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50), // 50 pixels padding
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    if (value.trim().isNotEmpty) {
      _fetchSchools(value.trim());
    }
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF3F51B5), // Blue background matching the UI
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.school,
            color: Color(0xFF3F51B5),
            size: 24,
          ),
        ),
        title: Text(
          school['name'] ?? 'Unknown School',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: school['address'] != null
            ? Text(
                school['address'],
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white70,
        ),
        onTap: () {
          // Move map to this school
          final lat = school['latitude'] ?? 0.0;
          final lng = school['longitude'] ?? 0.0;
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(lat, lng),
              15,
            ),
          );
          
          // Navigate to school selection screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolDetailsScreen(
                schoolId: school['id'] ?? 'Unknown',
                schoolName: school['name'] ?? 'Unknown School',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : const LatLng(6.9271, 79.8612),
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: true,
          ),

          // Search bar (positioned to match the UI)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80, // Below the header
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search your area',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // Enhanced bottom draggable sheet for schools list
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3F51B5),
                              ),
                            )
                          : _schools.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No schools found',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Try searching for a different area',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: EdgeInsets.only(top: 8, bottom: 20),
                                  itemCount: _schools.length,
                                  itemBuilder: (context, index) {
                                    final school = _schools[index];
                                    return _buildSchoolCard(school);
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}