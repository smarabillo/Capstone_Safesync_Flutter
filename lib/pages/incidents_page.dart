import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safesync/config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({super.key, required String userId});

  @override
  _IncidentsPageState createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  List<dynamic> _incidents = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Load the user_id from SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
    _fetchIncidents();
  }

  // Fetch incidents reported by the user
  Future<void> _fetchIncidents() async {
    if (_userId == null) return;

    try {
      // Adjust the URL with the proper query parameter for reported_by
      var uri = Uri.parse('${Config.fetchReportstUrl}?reported_by=$_userId');
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        if (result['status'] == 'success') {
          if (mounted) {
            setState(() {
              _incidents = result['data'];
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch incidents')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching incidents')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Center(
                  child: Text(
                    'No incidents available.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final incident = _incidents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  'Incident Code: ${incident['incident_code'] ?? 'N/A'}'),
                            ),
                            Text(
                              'Reported By: ${incident['reported_by'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${incident['incident_name'] ?? 'N/A'}'),
                            Text('Location: ${incident['location'] ?? 'N/A'}'),
                            Text(
                                'Description: ${incident['incident_desc'] ?? 'N/A'}'),
                            Text(
                                'Status: ${incident['incident_status'] ?? 'N/A'}'),
                            Text(
                                'Reported: ${incident['date_time_reported'] ?? 'N/A'}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
