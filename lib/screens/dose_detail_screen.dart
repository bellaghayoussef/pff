import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pff/screens/signature_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';

class DoseDetailScreen extends StatefulWidget {
  final int doseId;

  const DoseDetailScreen({Key? key, required this.doseId}) : super(key: key);

  @override
  _DoseDetailScreenState createState() => _DoseDetailScreenState();
}

class _DoseDetailScreenState extends State<DoseDetailScreen> {
  Map<String, dynamic>? _dose;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDoseDetails();
  }

  Future<void> _fetchDoseDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        developer.log('No token found, redirecting to login');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      developer.log('Fetching dose details for ID: ${widget.doseId}');

      final response = await http.get(
        Uri.parse('http://192.168.0.143:8000/api/doses/${widget.doseId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('data')) {
          setState(() {
            _dose = responseData['data'];
            _isLoading = false;
          });
          developer.log('Successfully loaded dose details');
        } else {
          setState(() {
            _error = 'Invalid response format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load dose details: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching dose details',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSignatureScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignatureScreen(doseId: widget.doseId),
      ),
    );

    if (result == true) {
      _fetchDoseDetails();
    }
  }

  Widget _buildSignatureSection() {
    if (_dose == null || _dose!['signature'] == null) {
      return ElevatedButton.icon(
        onPressed: _openSignatureScreen,
        icon: Icon(Icons.draw),
        label: Text('Add Signature'),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: 'http://192.168.0.143:8000/storage/${_dose!['signature']}',
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openSignatureScreen,
                  icon: Icon(Icons.edit),
                  label: Text('Update Signature'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dose Details'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _dose == null
          ? Center(child: Text('No data available'))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              'Basic Information',
              [
                _buildDetailRow('ID', _dose!['id'].toString()),
                _buildDetailRow('Status', _dose!['status']),
                _buildDetailRow(
                  'Created At',
                  _dose!['created_at'],
                ),
                _buildDetailRow(
                  'Updated At',
                  _dose!['updated_at'],
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailCard(
              'User Information',
              [
                _buildDetailRow('Name', _dose!['user']['name']),
                _buildDetailRow('Email', _dose!['user']['email']),
                _buildDetailRow(
                  'Agency ID',
                  _dose!['user']['agency_id'].toString(),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailCard(
              'Procedure Information',
              [
                _buildDetailRow('Name', _dose!['procedure']['name']),
                _buildDetailRow(
                  'Description',
                  _dose!['procedure']['description'],
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailCard(
              'Relations',
              [     
                _buildDetailRow(
                  'Procedure ID',
                  _dose!['procedure_id'].toString(),
                ),
                _buildDetailRow(
                  'Agency ID',
                  _dose!['agency_id'].toString(),
                ),
                _buildDetailRow(
                  'User ID',
                  _dose!['user_id'].toString(),
                ),
                _buildDetailRow(
                  'Task ID',
                  _dose!['task_id'].toString(),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildSignatureSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // Special handling for description
    if (label == 'Description') {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Regular row layout for other fields
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 