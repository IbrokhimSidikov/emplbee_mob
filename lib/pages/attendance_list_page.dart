import 'package:emplbee_mob/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/user_service.dart';
import '../models/attendance_model.dart';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage>
    with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  final _userService = UserService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  List<AttendanceModel> _attendances = [];
  bool _isLoading = true;

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
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    try {
      setState(() => _isLoading = true);

      // Get current user data using UserService
      final currentUser = await _userService.getCurrentUser();
      if (currentUser.memberId == null) {
        print('No memberId found for current user');
        return;
      }

      // Fetch member details including attendance
      final details =
          await _userService.getMemberDetails(currentUser.memberId!);
      print('Fetched member details for ID ${currentUser.memberId}');

      final attendances = details['attendances'] as List?;
      if (attendances != null && attendances.isNotEmpty) {
        final parsedAttendances = attendances.map((attendance) {
          return AttendanceModel.fromJson(attendance);
        }).toList();

        setState(() {
          _attendances = parsedAttendances;
          _attendances.sort((a, b) => b.checkIn.compareTo(a.checkIn));
        });
      } else {
        print('No attendance records found');
        setState(() => _attendances = []);
      }
    } catch (e) {
      print('Error loading attendance data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return '-';
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Color(
                int.parse(attendance.getStatusColor().replaceAll('#', '0xFF'))),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(attendance
                                  .getStatusColor()
                                  .replaceAll('#', '0xFF')))
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Color(int.parse(attendance
                              .getStatusColor()
                              .replaceAll('#', '0xFF'))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        attendance.getFormattedDate(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(attendance
                              .getStatusColor()
                              .replaceAll('#', '0xFF')))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      attendance.checkInStatus.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Color(int.parse(attendance
                            .getStatusColor()
                            .replaceAll('#', '0xFF'))),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeInfo(
                    AppLocalizations.of(context).checkIn,
                    attendance.getFormattedCheckIn(),
                    Icons.login,
                    Colors.green,
                    attendance.lateMinutes != '0м'
                        ? attendance.lateMinutes
                        : null,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  _buildTimeInfo(
                    AppLocalizations.of(context).checkOut,
                    attendance.getFormattedCheckOut(),
                    Icons.logout,
                    Colors.red,
                    attendance.earlyMinutes != '0м'
                        ? attendance.earlyMinutes
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.access_time,
                    attendance.getShiftTime(),
                    Colors.blue.shade100,
                    Colors.blue.shade700,
                  ),
                  _buildInfoChip(
                    Icons.timer,
                    attendance.getFormattedDuration(),
                    Colors.green.shade100,
                    Colors.green.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
      String label, String time, IconData icon, Color color, String? subtitle) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: fgColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).attendanceHistory,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Summary
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        AppLocalizations.of(context).totalHours,
                        '${_attendances.fold<int>(0, (sum, attendance) => sum + (attendance.checkOut?.difference(attendance.checkIn).inHours ?? 0))}h',
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        AppLocalizations.of(context).entries,
                        _attendances.length.toString(),
                        Icons.fact_check,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Entries List
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadAttendanceData,
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color.fromARGB(255, 37, 134, 237),
                                    ),
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading attendance...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _attendances.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No attendance records',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _attendances.length,
                                itemBuilder: (context, index) {
                                  return _buildAttendanceCard(
                                      _attendances[index]);
                                },
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
