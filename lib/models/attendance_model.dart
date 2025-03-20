import 'package:intl/intl.dart';
import 'dart:convert';

class AttendanceModel {
  final String id;
  final String code;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status;
  final String? note;
  final String memberId;
  final bool isCheckInManual;
  final bool isCheckOutManual;
  final String? checkInPhotoId;
  final String? checkOutPhotoId;
  final String? total;
  final String checkInStatus;
  final String lateMinutes;
  final String earlyMinutes;
  final String? timesheetId;
  final Map<String, dynamic>? shift;

  AttendanceModel({
    required this.id,
    required this.code,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.note,
    required this.memberId,
    required this.isCheckInManual,
    required this.isCheckOutManual,
    this.checkInPhotoId,
    this.checkOutPhotoId,
    this.total,
    required this.checkInStatus,
    required this.lateMinutes,
    required this.earlyMinutes,
    this.timesheetId,
    this.shift,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? shiftData;
    if (json['shift'] != null) {
      if (json['shift'] is String) {
        shiftData = Map<String, dynamic>.from(jsonDecode(json['shift']));
      } else {
        shiftData = Map<String, dynamic>.from(json['shift']);
      }
    }

    return AttendanceModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      checkIn: DateTime.parse(json['checkIn'] ?? json['check_in']),
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'])
          : json['check_out'] != null
              ? DateTime.parse(json['check_out'])
              : null,
      status: json['status'] ?? '',
      note: json['note'],
      memberId: json['memberId'] ?? json['member_id'] ?? '',
      isCheckInManual:
          json['isCheckInManual'] == 1 || json['is_check_in_manual'] == 1,
      isCheckOutManual:
          json['isCheckOutManual'] == 1 || json['is_check_out_manual'] == 1,
      checkInPhotoId: json['checkInPhotoId'] ?? json['check_in_photo_id'],
      checkOutPhotoId: json['checkOutPhotoId'] ?? json['check_out_photo_id'],
      total: json['total'],
      checkInStatus: json['checkInStatus'] ?? json['check_in_status'] ?? '',
      lateMinutes: json['lateMinutes'] ?? json['late_minutes'] ?? '0м',
      earlyMinutes: json['earlyMinutes'] ?? json['early_minutes'] ?? '0м',
      timesheetId: json['timesheetId'] ?? json['timesheet_id'],
      shift: shiftData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'status': status,
      'note': note,
      'memberId': memberId,
      'isCheckInManual': isCheckInManual ? 1 : 0,
      'isCheckOutManual': isCheckOutManual ? 1 : 0,
      'checkInPhotoId': checkInPhotoId,
      'checkOutPhotoId': checkOutPhotoId,
      'total': total,
      'checkInStatus': checkInStatus,
      'lateMinutes': lateMinutes,
      'earlyMinutes': earlyMinutes,
      'timesheetId': timesheetId,
      'shift': shift != null ? jsonEncode(shift) : null,
    };
  }

  String getFormattedCheckIn() {
    return DateFormat('HH:mm').format(checkIn);
  }

  String getFormattedCheckOut() {
    return checkOut != null ? DateFormat('HH:mm').format(checkOut!) : '-';
  }

  String getFormattedDate() {
    return DateFormat('dd MMM yyyy').format(checkIn);
  }

  Duration? getDuration() {
    return checkOut != null ? checkOut!.difference(checkIn) : null;
  }

  String getFormattedDuration() {
    if (total != null) return total!;
    final duration = getDuration();
    if (duration == null) return '-';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String getShiftTime() {
    if (shift == null) return '-';
    return '${shift!['startTime']} - ${shift!['endTime']}';
  }

  String getStatusColor() {
    switch (checkInStatus.toLowerCase()) {
      case 'late':
        return '#FFA500'; // Orange
      case 'ontime':
        return '#4CAF50'; // Green
      default:
        return '#757575'; // Grey
    }
  }
}

// models/task_model.dart
class TaskModel {
  final String id;
  final String title;
  final String status;

  TaskModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        status = json['status'];
}
