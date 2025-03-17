import 'dart:convert';

class UserModel {
  final String id;
  final String auth_id;
  final String email;
  final String username;
  final String? name;
  final String? position;
  final String? phone;
  final String? photo;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.auth_id,
    required this.email,
    required this.username,
    this.name,
    this.position,
    this.phone,
    this.photo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      auth_id: json['auth_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      name: json['name'],
      position: json['position'],
      phone: json['phone'],
      photo: json['photo'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': auth_id,
      'email': email,
      'username': username,
      'name': name,
      'position': position,
      'phone': phone,
      'photo': photo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
