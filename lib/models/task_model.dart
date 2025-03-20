import 'package:intl/intl.dart';

class TaskModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String type;
  final String? priority;
  final DateTime startDate;
  final DateTime deadline;
  final String code;
  final String assigneeId;
  final String controllerId;
  final String statusId;
  final int position;
  final TaskStatus status;

  TaskModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.type,
    this.priority,
    required this.startDate,
    required this.deadline,
    required this.code,
    required this.assigneeId,
    required this.controllerId,
    required this.statusId,
    required this.position,
    required this.status,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      type: json['type'] ?? '',
      priority: json['priority'],
      startDate: DateTime.parse(json['startDate']),
      deadline: DateTime.parse(json['deadline']),
      code: json['code'] ?? '',
      assigneeId: json['assigneeId'] ?? '',
      controllerId: json['controllerId'] ?? '',
      statusId: json['statusId'] ?? '',
      position: json['position'] ?? 0,
      status: TaskStatus.fromJson(json['status'] ?? {}),
    );
  }

  String getFormattedDeadline() {
    return DateFormat('dd MMM yyyy').format(deadline);
  }

  String getFormattedStartDate() {
    return DateFormat('dd MMM yyyy').format(startDate);
  }

  bool isOverdue() {
    return DateTime.now().isAfter(deadline);
  }
}

class TaskStatus {
  final String id;
  final String name;
  final String type;
  final String category;
  final int position;
  final DateTime createdAt;

  TaskStatus({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.position,
    required this.createdAt,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      position: json['position'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
