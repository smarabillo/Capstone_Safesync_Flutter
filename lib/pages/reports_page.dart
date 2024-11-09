import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safesync/pages/home.dart'; // Import home.dart for buildAppBar
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';


class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _userId, _selectedIncidentCode, _incidentName, _location;
  DateTime? _incidentDateTime;
  bool _isLoadingIncidentTypes = true;
  File? _image;
  List<IncidentType> _incidentTypes = [];
  final ImagePicker _picker = ImagePicker();
  late MapController _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.white),
    );
    _mapController = MapController();
    _loadUserId();
    _initializeLocation();
    _initializeIncidentTypes();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getString('user_id'));
  }

  Future<void> _initializeLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _location =
              "Lat: ${position.latitude}, Lon: ${position.longitude}"; // Store the lat/lon as a string
        });
        _mapController.move(_currentPosition!, 16.0);
      }
    } else {
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() => _location = "Location permission denied");
      }
    }
  }

  void _centerOnLocation() {
    if (_currentPosition != null) {
      _mapController.move(
          _currentPosition!, 16.0); // Adjust zoom level as necessary
    } else {
      // You can handle location permission denied or loading state here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch current location')),
      );
    }
  }

  Future<void> _initializeIncidentTypes() async {
    try {
      final response = await http.get(
          Uri.parse('https://safesync.helioho.st/classes/class-incident.php'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _incidentTypes = data
                .map((item) =>
                    IncidentType(item['incident_code'], item['incident_name']))
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
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() => _isLoadingIncidentTypes = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final request = http.MultipartRequest(
        'POST', Uri.parse('http://10.0.2.2/safesync-api/submit_report.php'))
      ..fields['user_id'] = _userId!
      ..fields['incident_code'] = _selectedIncidentCode!
      ..fields['incident_name'] = _incidentName!
      ..fields['location'] = _location!
      ..fields['incident_desc'] = 'Incident description here'
      ..fields['incident_datetime'] =
          _incidentDateTime?.toIso8601String() ?? '';

    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = json.decode(responseData.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(),
      body: _isLoadingIncidentTypes
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildReadOnlyTextField('Reported By', _userId),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildIncidentDropdown(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildReadOnlyTextField(
                            'Incident Name', _incidentName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildMapContainer(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildReadOnlyTextField('Location', _location),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildDescriptionField(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildDateTimeField(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildImagePickerContainer(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildSubmitButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String? initialValue) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: const OutlineInputBorder(
          borderSide:
              BorderSide(color: Colors.black26, width: 1.0), // Default border
        ),
        contentPadding: const EdgeInsets.all(12.0),
      ),
      readOnly: true,
      initialValue: initialValue,
    );
  }

  Widget _buildIncidentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
          labelText: 'Incident Code',
          border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black26))),
      value: _selectedIncidentCode,
      onChanged: (newValue) {
        setState(() {
          _selectedIncidentCode = newValue;
          _incidentName =
              _incidentTypes.firstWhere((type) => type.code == newValue).name;
        });
      },
      items: _incidentTypes
          .map((incident) => DropdownMenuItem<String>(
                value: incident.code,
                child: Text('${incident.code} - ${incident.name}'),
              ))
          .toList(),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      height: 250,
      child: FlutterMap(
        mapController: _mapController, // Use the initialized controller
        options: MapOptions(
          center: _currentPosition ?? LatLng(0, 0),
          zoom: 16.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _currentPosition != null
                ? [
                    Marker(
                      point: _currentPosition!,
                      builder: (context) =>
                          const Icon(Icons.location_on, color: Colors.red),
                    ),
                  ]
                : [],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: _centerOnLocation,
              child: const Icon(
                Icons.my_location_rounded,
                color: Colors.white,
              ),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Incident Description',
        enabledBorder: const OutlineInputBorder(
          borderSide:
              BorderSide(color: Colors.black26, width: 1.0), // Default border
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildDateTimeField() {
  return TextFormField(
    decoration: const InputDecoration(
      labelText: 'Incident Date & Time',
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black26, width: 1.0),
      ),
    ),
    readOnly: true,
    onTap: () async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          setState(() {
            _incidentDateTime = selectedDateTime;
          });
        }
      }
    },
    controller: TextEditingController(
      text: _incidentDateTime != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_incidentDateTime!)
          : 'Select Date & Time',
    ),
  );
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
          height: 130,
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
    return TextButton(
      onPressed: _submitReport,
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue, // Background color
        foregroundColor: Colors.white, // Text color
        padding:
            EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0), // Padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
        ),
        side:
            BorderSide(color: Colors.blue, width: 1), // Border color and width
      ),
      child: const Text('Submit Report'),
    );
  }
}

class IncidentType {
  final String code;
  final String name;

  IncidentType(this.code, this.name);
}
