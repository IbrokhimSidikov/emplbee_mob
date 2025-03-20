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

      // if (details['attendances'] != null) {
      //   final attendancesList = details['attendances'] as List;
      //   final parsedAttendances = attendancesList.map((attendance) {
      //     final model = AttendanceModel.fromJson(attendance);
      //     print('Parsed attendance: ${json.encode({
      //           'date': model.getFormattedDate(),
      //           'checkIn': model.getFormattedCheckIn(),
      //           'checkOut': model.getFormattedCheckOut(),
      //           'duration': model.getFormattedDuration(),
      //           'status': model.status
      //         })}');
      //     return model;
      //   }).toList();

      //   setState(() {
      //     _attendances = parsedAttendances;
      //     _attendances.sort((a, b) => b.checkIn.compareTo(a.checkIn));
      //   });
      // }
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
    final bool isToday = attendance.checkIn.day == DateTime.now().day;
    return Card(
      elevation: isToday ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: isToday
              ? Border.all(color: Colors.blue.shade200, width: 1.5)
              : null,
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
                          color: isToday
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: isToday
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        attendance.getFormattedDate(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: attendance.checkOut != null
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      attendance.checkOut != null
                          ? AppLocalizations.of(context).completed
                          : AppLocalizations.of(context).inProgress,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: attendance.checkOut != null
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
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
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  _buildTimeInfo(
                    AppLocalizations.of(context).checkOut,
                    attendance.checkOut != null
                        ? attendance.getFormattedCheckOut()
                        : '-',
                    Icons.logout,
                    Colors.red,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  _buildTimeInfo(
                    AppLocalizations.of(context).duration,
                    _formatDuration(attendance.checkIn, attendance.checkOut),
                    Icons.timer,
                    Colors.blue,
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
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
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
                        ? const Center(
                            child: CircularProgressIndicator(),
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
