import 'package:emplbee_mob/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import './attendance_list_page.dart';
import './tasks.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  UserModel? _user;
  double totalWorkedHours = 0;
  final double salary = 15000000;
  final int workedHours = 160;
  final int availableOffDays = 15;
  bool isOnline = false;
  final _storage = FlutterSecureStorage();
  final _authService = AuthService();
  final _userService = UserService(); // Initialize UserService

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
    _loadUserProfile();
    _loadAttendanceStatus();
    _calculateTotalHours();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get user data from UserService which prioritizes configdata
      final user = await _userService.getCurrentUser();
      print(
          'ProfilePage: Loaded user data - name: ${user.name}, username: ${user.username}');

      setState(() {
        _user = user;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      // Fallback to cached data
      final userJson = await _storage.read(key: 'user_profile');
      if (userJson != null) {
        final cachedUser = UserModel.fromJson(json.decode(userJson));
        print(
            'ProfilePage: Using cached user data - name: ${cachedUser.name}, username: ${cachedUser.username}');
        setState(() {
          _user = cachedUser;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceStatus() async {
    final status = await _storage.read(key: 'attendance_status');
    setState(() {
      isOnline = status == 'checked_in';
    });
  }

  Future<void> _updateAttendanceStatus(bool isOnline) async {
    try {
      final success = await AuthService()
          .updateMemberStatus(isOnline ? 'online' : 'offline');
      if (success) {
        setState(() {
          this.isOnline = isOnline;
        });
        await _storage.write(
            key: 'attendance_status',
            value: isOnline ? 'checked_in' : 'checked_out');
        print(
            'Attendance status updated successfully to: ${isOnline ? 'online' : 'offline'}');
      } else {
        print('Failed to update attendance status');
      }
    } catch (e) {
      print('Error updating attendance status: $e');
    }
  }

  Future<void> _calculateTotalHours() async {
    final entriesJson = await _storage.read(key: 'work_entries');
    if (entriesJson != null) {
      final List<dynamic> entries = json.decode(entriesJson);
      double total = 0;

      for (var entry in entries) {
        final checkIn = DateTime.parse(entry['checkIn']);
        final checkOut = entry['checkOut'] != null
            ? DateTime.parse(entry['checkOut'])
            : null;

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
    Color? iconColor,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor ?? Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            const Icon(Icons.logout_rounded, color: Colors.red),
                        onPressed: () async {
                          print('ProfilePage: Logout button pressed');
                          try {
                            print('ProfilePage: Starting logout process');
                            await AuthService().logout();
                            print(
                                'ProfilePage: Logout successful, navigating to onboard page');
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/', (route) => false);
                            print('ProfilePage: Navigation complete');
                          } catch (e) {
                            print('ProfilePage: Logout failed with error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Logout failed: ${e.toString()}',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            print('ProfilePage: Error snackbar shown to user');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Profile Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: _user?.photo != null
                                  ? NetworkImage(_user!.photo!)
                                  : null,
                              child: _user?.photo == null
                                  ? Text(
                                      (_user?.name ?? _user?.username ?? '')
                                          .split(' ')
                                          .map((e) => e.isNotEmpty
                                              ? e[0].toUpperCase()
                                              : '')
                                          .join(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _updateAttendanceStatus(!isOnline),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Display name from configdata, fallback to username if not available
                        Text(
                          _user?.name ?? _user?.username ?? 'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.type ?? 'Ishchi',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.code ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildInfoCard(
                        title: AppLocalizations.of(context).totalHours,
                        value: '$totalWorkedHours hrs',
                        icon: Icons.access_time,
                        iconColor: Colors.blue,
                        isHighlighted: true,
                      ),
                      _buildInfoCard(
                        title: AppLocalizations.of(context).monthlyHours,
                        value: '$workedHours hrs',
                        icon: Icons.calendar_today,
                        iconColor: Colors.purple,
                      ),
                      _buildInfoCard(
                        title: AppLocalizations.of(context).availableOffDays,
                        value: '$availableOffDays days',
                        icon: Icons.beach_access,
                        iconColor: Colors.orange,
                      ),
                      _buildInfoCard(
                        title: AppLocalizations.of(context).monthlySalary,
                        value: '\$${(salary / 1000000).toStringAsFixed(1)}M',
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                // Additional Info Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).quickActions,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildActionTile(
                              AppLocalizations.of(context).requestTimeOff,
                              Icons.event_available,
                              () {
                                // TODO: Implement time off request
                              },
                            ),
                            const Divider(height: 1),
                            _buildActionTile(
                              AppLocalizations.of(context)
                                  .viewAttendanceHistory,
                              Icons.history,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AttendanceListPage(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _buildActionTile(
                              'Tasks', // TODO: Add to localizations
                              Icons.task_alt,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TasksPage(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _buildActionTile(
                              AppLocalizations.of(context).downloadPayslip,
                              Icons.description,
                              () {
                                // TODO: Implement pay slip download
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
