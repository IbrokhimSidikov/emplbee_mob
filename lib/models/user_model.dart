import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final DateTime? emailVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    this.emailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['sub'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      picture: json['picture'],
      emailVerified: json['email_verified'] != null
          ? DateTime.parse(json['email_verified'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': id,
      'email': email,
      'name': name,
      'picture': picture,
      'email_verified': emailVerified?.toIso8601String(),
    };
  }
}
