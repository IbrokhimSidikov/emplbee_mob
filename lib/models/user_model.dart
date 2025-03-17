import 'dart:convert';

class UserModel {
  final String id;
  final String auth_id;
  final String email;
  final String username;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.auth_id,
    required this.email,
    required this.username,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      auth_id: json['auth_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'auth_id': auth_id,
        'email': email,
        'username': username,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
