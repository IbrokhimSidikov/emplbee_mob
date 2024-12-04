import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String employeeName = "Ibrokhim Sidikov";
  final String position = "Software Engineer";
  final String email = "ibrokhim.sidikov@emplbee.com";
  double totalWorkedHours = 0;
  final double salary = 15000000;
  final int workedHours = 160;
  final int availableOffDays = 15;
  String? profileImageUrl;
  bool isOnline = false;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // TODO: Load profile image URL from your data source
    // For example: profileImageUrl = await getUserProfileImage();
    _loadAttendanceStatus();
    _calculateTotalHours();
  }

  Future<void> _loadAttendanceStatus() async {
    final status = await _storage.read(key: 'attendance_status');
    setState(() {
      isOnline = status == 'checked_in';
    });
  }

  Future<void> _calculateTotalHours() async {
    final entriesJson = await _storage.read(key: 'work_entries');
    if (entriesJson != null) {
      final List<dynamic> entries = json.decode(entriesJson);
      double total = 0;
      
      for (var entry in entries) {
        final checkIn = DateTime.parse(entry['checkIn']);
        final checkOut = entry['checkOut'] != null ? DateTime.parse(entry['checkOut']) : null;
        
        if (checkOut != null) {
          final duration = checkOut.difference(checkIn);
          total += duration.inMinutes / 60;
        }
      }
      
      setState(() {
        totalWorkedHours = double.parse(total.toStringAsFixed(1));
      });
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 4,
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue[700]),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/homepage');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImageUrl != null 
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child: profileImageUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    employeeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    position,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Text(
                      'This Month\'s Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildInfoCard(
                        title: 'Worked Hours',
                        value: '$totalWorkedHours hrs',
                        icon: Icons.access_time,
                      ),
                      _buildInfoCard(
                        title: 'Generated Salary',
                        value: '$salary\n\UZS',
                        icon: Icons.attach_money,
                      ),
                      _buildInfoCard(
                        title: 'Available Off Days',
                        value: '$availableOffDays days',
                        icon: Icons.event_available,
                      ),
                      _buildInfoCard(
                        title: 'Performance',
                        value: 'Excellent',
                        icon: Icons.trending_up,
                        backgroundColor: Colors.green[50],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}