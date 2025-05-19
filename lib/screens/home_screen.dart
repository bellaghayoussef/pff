import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pff/screens/dose_detail_screen.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer; // Add this import for logging


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _doses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDoses();
  }

  Future<void> _fetchDoses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        developer.log('No token found, redirecting to login');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      developer.log('Fetching doses with token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('http://192.168.0.143:8000/api/doses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        developer.log('Decoded response: $responseData');

        if (responseData.containsKey('data') && responseData['data'] is List) {
          setState(() {
            _doses = responseData['data'];
            _isLoading = false;
          });
          developer.log('Successfully loaded ${_doses.length} doses');
        } else {
          setState(() {
            _error = 'Invalid response format: data field is not a list';
            _isLoading = false;
          });
          developer.log('Invalid response format: ${responseData['data']}');
        }
      } else {
        setState(() {
          _error = 'Failed to load doses: ${response.body}';
          _isLoading = false;
        });
        developer.log('Failed to load doses: ${response.body}', error: 'API Error');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching doses',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doses List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchDoses,
                  child: ListView.builder(
                    itemCount: _doses.length,
                    itemBuilder: (context, index) {
                      final dose = _doses[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          title: Text('Dossier #${dose['id']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${dose['status']}'),
                              Text('Created: ${dose['created_at']}'),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoseDetailScreen(doseId: dose['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 