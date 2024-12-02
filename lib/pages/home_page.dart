import 'package:flutter/material.dart';
import 'attendance.dart'; // Ensure this import points to the correct location of your AttendanceScreen

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Page',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildCard(
                context, 'Profile', Icons.person_4_outlined, Colors.white, '/profilepage'),
            _buildCard(
                context, 'Salary', Icons.attach_money, Colors.white, '/salarypage'),
            _buildCard(
                context, 'Attendance', Icons.done_outline, Colors.white, null),
            _buildCard(
                context, 'Tasks', Icons.task_outlined, Colors.white, '/taskspage'),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String label, IconData icon, Color color, String? routeName) {
    return GestureDetector(
      onTap: () {
        if (routeName != null) {
          Navigator.pushReplacementNamed(context, routeName);
        } else {
          // Specific navigation for Attendance
          _navigateToAttendance(context);
        }
      },
      child: Card(
        color: Color(0xFF17284d),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: color,
            ),
            SizedBox(height: 16.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAttendance(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AttendanceScreen()),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Check-in successful!")),
      );
    }
  }
}
