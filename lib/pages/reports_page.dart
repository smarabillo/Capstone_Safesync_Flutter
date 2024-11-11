import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safesync/config.dart';
import 'package:safesync/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _formKey = GlobalKey<FormState>();

  // State variables
  String? _userId, _selectedIncidentCode, _incidentName, _location;
  String? base64Image;
  DateTime? _incidentDateTime;
  bool _isLoadingIncidentTypes = true;
  File? _image;
  List<IncidentType> _incidentTypes = [];
  final ImagePicker _picker = ImagePicker();
  MapController? _mapController;
  LatLng? _currentPosition;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.white));
    _incidentDateTime = DateTime.now();
    _loadUserId();
    _initializeLocation();
    _initializeIncidentTypes();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      _location = prefs.getString('location') ?? "Location not available";
    });
  }

  Future<void> _initializeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final status = await Permission.location.request();

    if (status.isGranted) {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        _updateLocation(position.latitude, position.longitude);
        prefs.setString('location', _location!);
        _mapController?.move(_currentPosition!, 16.0);
      }
    } else {
      if (mounted) {
        setState(() => _location = "Location permission denied");
      }
    }
  }

  void _updateLocation(double latitude, double longitude) {
    setState(() {
      _currentPosition = LatLng(latitude, longitude);
      _location = "$latitude, $longitude";
    });
  }

  void _centerOnLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.move(_currentPosition!, 16.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch current location')),
      );
    }
  }

  Future<void> _initializeIncidentTypes() async {
    try {
      // API fetching incidents
      final response = await http.get(Uri.parse(Config.fetchIncidentUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        if (mounted) {
          setState(() {
            _incidentTypes = data
                .map((item) => IncidentType(
                    item['incident_code'].toString(), item['incident_name']))
                .toList();
            _selectedIncidentCode = _incidentTypes.first.code;
            _incidentName = _incidentTypes.first.name;
          });
        }
      } else {
        throw Exception('Failed to load incident types');
      }
    } catch (e) {
      print("Error fetching incident types: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingIncidentTypes = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> submitReport() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Format datetime properly - ensure it's not null
        String formattedDateTime = _incidentDateTime != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_incidentDateTime!)
            : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        // Validate all required fields before creating request
        if (_userId?.isEmpty ?? true) {
          _showErrorDialog("User ID is required");
          return;
        }

        if (_selectedIncidentCode?.isEmpty ?? true) {
          _showErrorDialog("Incident Code is required");
          return;
        }

        if (_location?.isEmpty ?? true) {
          _showErrorDialog("Location is required");
          return;
        }

        if (_descriptionController.text.trim().isEmpty) {
          _showErrorDialog("Description is required");
          return;
        }

        // Prepare the report data
        Map<String, String> reportData = {
          'reported_by': _userId!,
          'incident_code': _selectedIncidentCode!,
          'location': _location!,
          'incident_desc': _descriptionController.text.trim(),
          'date_time_reported': formattedDateTime,
          'incident_status': 'Reported',
        };

        // Prepare the request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(Config.createReportUrl),
        );

        // Add fields
        reportData.forEach((key, value) {
          request.fields[key] = value;
        });

        // Add the image file if it exists
        if (_image != null) {
          print("Adding image to request: ${_image!.path}");
          request.files.add(await http.MultipartFile.fromPath(
            'incident_img', // Field name must match PHP (incident_img)
            _image!.path,
          ));
        } else {
          print("No image selected.");
        }

        // Send the request
        var response = await request.send();

        // Handle the response
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          print('Response: $responseBody');

          // Handle successful response
          final data = json.decode(responseBody);
          if (data['status'] == 'success') {
            _showSuccessDialog(
                data['message'] ?? 'Report submitted successfully');
            _clearForm();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const SafeSyncDashboard()),
            );
          } else {
            _showErrorDialog(data['message'] ?? 'Failed to submit report');
          }
        } else {
          _showErrorDialog('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print("Error during API call: $e");
        _showErrorDialog("Network error. Please check your connection.");
      }
    } else {
      _showErrorDialog("Please fill all the required fields correctly.");
    }
  }

  void _clearForm() {
    setState(() {
      _descriptionController.clear();
      _image = null;
      _incidentDateTime = null;
    });
  }

// Add this helper function to validate data
  bool _validateData() {
    print('Validating fields:');
    print('User ID: $_userId');
    print('Incident Code: $_selectedIncidentCode');
    print('Location: $_location');
    print('Description: ${_descriptionController.text}');
    print('DateTime: $_incidentDateTime');

    return _userId?.isNotEmpty == true &&
        _selectedIncidentCode?.isNotEmpty == true &&
        _location?.isNotEmpty == true &&
        _descriptionController.text.trim().isNotEmpty &&
        _incidentDateTime != null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Error', selectionColor: Colors.redAccent,),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK', selectionColor: Colors.black,),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Success', selectionColor: Colors.greenAccent,),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK', selectionColor: Colors.black,),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Report Incident"),
        foregroundColor: Colors.blueAccent,
        backgroundColor: Colors.white,
      ),
      body: _isLoadingIncidentTypes
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Reduced padding for consistency
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyTextField('Reported By', _userId),
              _buildIncidentDropdown(),
              _buildReadOnlyTextField('Incident Name', _incidentName),
              _buildMapContainer(),
              _buildReadOnlyTextField('Location', _location),
              _buildDescriptionField(),
              _buildDateTimeField(),
              _buildImagePickerContainer(),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String? initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black26)),
          contentPadding: const EdgeInsets.all(12.0),
        ),
        readOnly: true,
        initialValue: initialValue,
      ),
    );
  }

  Widget _buildIncidentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Incident Code',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
      ),
      value: _selectedIncidentCode,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedIncidentCode = newValue;
            // Find the incident type object based on the selected code
            final selectedIncident = _incidentTypes.firstWhere(
              (incident) => incident.code == newValue,
              orElse: () => IncidentType(
                  'manual', 'Manual Entry'), // Default if not found
            );
            _incidentName = selectedIncident.name;
          });
        }
      },
      items: _incidentTypes.map((incident) {
        return DropdownMenuItem<String>(
          value: incident.code,
          child: Text('${incident.code} - ${incident.name}'),
        );
      }).toList(),
    );
  }

  Widget _buildMapContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: FlutterMap(
          mapController: _mapController ??= MapController(),
          options:
              MapOptions(center: _currentPosition ?? LatLng(0, 0), zoom: 16.0),
          children: [
            TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c']),
            if (_currentPosition != null)
              MarkerLayer(markers: [
                Marker(
                    point: _currentPosition!,
                    builder: (_) =>
                        const Icon(Icons.location_on, color: Colors.red))
              ]),
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                mini: true,
                onPressed: _centerOnLocation,
                backgroundColor: Theme.of(context).primaryColor,
                child:
                    const Icon(Icons.my_location_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Incident Description',
          border: OutlineInputBorder(),
          hintText: 'Enter incident description here',
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please provide a description';
          }
          return null;
        },
        onChanged: (value) {
          // Optional: Add this to see the value changing
          print('Description updated: $value');
        },
      ),
    );
  }

  Widget _buildDateTimeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Date & Time',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateTime,
          ),
        ),
        controller: TextEditingController(
          text: _incidentDateTime != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(_incidentDateTime!)
              : '',
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(picked),
      );
      if (timePicked != null) {
        setState(() {
          _incidentDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Widget _buildImagePickerContainer() {
    return GestureDetector(
        onTap: () async {
          // Show a dialog to choose between taking a picture or uploading a file
          final pickedOption = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Choose Image Source'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop('camera');
                    },
                    child: const Text('Take a Picture'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop('gallery');
                    },
                    child: const Text('Choose from Gallery'),
                  ),
                ],
              );
            },
          );

          if (pickedOption != null) {
            if (pickedOption == 'camera') {
              await _pickImage(ImageSource.camera);
            } else if (pickedOption == 'gallery') {
              await _pickImage(ImageSource.gallery);
            }
          }
        },
        child: Container(
          height: 100,
          width: double.infinity, // Make the container stretch to full width
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.black12,
          ),
          clipBehavior: Clip.hardEdge, // Ensures any overflow is clipped
          child: _image == null
              ? const Center(
                  child: Text(
                    'Select or Take Image Here',
                    style: TextStyle(
                      overflow: TextOverflow
                          .ellipsis, // Ensure text does not overflow
                      fontSize: 14, // Adjust font size if necessary
                    ),
                  ),
                ) // Display message if no image is selected
              : Image.file(
                  _image!,
                  width: double
                      .infinity, // Make the image fill the container width
                  fit: BoxFit
                      .cover, // Ensures the image covers the container without overflowing
                ),
        ));
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: ElevatedButton(
          onPressed:
              submitReport, // Fix here: Change _submitReport to submitReport
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent, // Button color
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 50.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Submit Report',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class IncidentType {
  final String code;
  final String name;

  IncidentType(this.code, this.name);
}
