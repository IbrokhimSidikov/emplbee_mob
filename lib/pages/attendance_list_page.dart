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
  bool _isLoadingMore = false;
  String? _memberId;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

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

    // Setup scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Load cached data first, then fetch fresh data
    _loadCachedData();
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreAttendanceData();
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedData = await _storage.read(key: 'attendance_data');
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final parsedAttendances = decodedData.map((attendance) {
          return AttendanceModel.fromJson(attendance);
        }).toList();

        setState(() {
          _attendances = parsedAttendances;
          _attendances.sort((a, b) => b.checkIn.compareTo(a.checkIn));
        });
      }
    } catch (e) {
      print('Error loading cached attendance data: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
      });

      // Get current user data using UserService
      final currentUser = await _userService.getCurrentUser();
      if (currentUser.memberId == null) {
        print('No memberId found for current user');
        return;
      }

      _memberId = currentUser.memberId;

      // Fetch paginated attendance data
      final attendances =
          await _fetchAttendanceData(_memberId!, _currentPage, _pageSize);

      if (attendances.isNotEmpty) {
        setState(() {
          _attendances = attendances;
          _hasMoreData = attendances.length >= _pageSize;
        });

        // Cache the data
        _cacheAttendanceData(attendances);
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

  Future<void> _loadMoreAttendanceData() async {
    if (_isLoadingMore || !_hasMoreData || _memberId == null) return;

    try {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      final newAttendances =
          await _fetchAttendanceData(_memberId!, _currentPage, _pageSize);

      if (newAttendances.isNotEmpty) {
        setState(() {
          _attendances.addAll(newAttendances);
          _hasMoreData = newAttendances.length >= _pageSize;
        });

        // Update cache with all data
        _cacheAttendanceData(_attendances);
      } else {
        setState(() => _hasMoreData = false);
      }
    } catch (e) {
      print('Error loading more attendance data: $e');
      // Revert page count on error
      setState(() => _currentPage--);
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<List<AttendanceModel>> _fetchAttendanceData(
      String memberId, int page, int pageSize) async {
    try {
      // Fetch member details with pagination parameters
      final details =
          await _userService.getMemberAttendances(memberId, page, pageSize);

      final attendances = details['attendances'] as List?;
      if (attendances != null && attendances.isNotEmpty) {
        final parsedAttendances = attendances.map((attendance) {
          return AttendanceModel.fromJson(attendance);
        }).toList();

        // Sort by check-in date
        parsedAttendances.sort((a, b) => b.checkIn.compareTo(a.checkIn));
        return parsedAttendances;
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
    }
    return [];
  }

  Future<void> _cacheAttendanceData(List<AttendanceModel> attendances) async {
    try {
      final jsonData = attendances.map((a) => a.toJson()).toList();
      await _storage.write(
        key: 'attendance_data',
        value: json.encode(jsonData),
      );
    } catch (e) {
      print('Error caching attendance data: $e');
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
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).attendanceHistory,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAttendanceData,
            tooltip: AppLocalizations.of(context).refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceData,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                // Stats section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).attendanceStats,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              AppLocalizations.of(context).onTime,
                              _attendances
                                  .where((a) =>
                                      a.checkInStatus.toLowerCase() == 'ontime')
                                  .length
                                  .toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              AppLocalizations.of(context).late,
                              _attendances
                                  .where((a) =>
                                      a.checkInStatus.toLowerCase() == 'late')
                                  .length
                                  .toString(),
                              Icons.warning,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Attendance list
                Expanded(
                  child: _isLoading && _attendances.isEmpty
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
                                AppLocalizations.of(context).loadingAttendance,
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
                              controller: _scrollController,
                              itemCount:
                                  _attendances.length + (_hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _attendances.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color.fromARGB(
                                                255, 37, 134, 237),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return _buildAttendanceCard(
                                    _attendances[index]);
                              },
                            ),
                ),
              ],
            ),
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
