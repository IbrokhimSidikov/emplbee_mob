import 'package:intl/intl.dart';

class AttendanceModel {
  final String id;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status;
  final String? note;
  final String memberId;

  AttendanceModel({
    required this.id,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.note,
    required this.memberId,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      checkIn: DateTime.parse(json['check_in']),
      checkOut:
          json['check_out'] != null ? DateTime.parse(json['check_out']) : null,
      status: json['status'] ?? '',
      note: json['note'],
      memberId: json['memberId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'status': status,
      'note': note,
      'memberId': memberId,
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
    final duration = getDuration();
    if (duration == null) return '-';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
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
