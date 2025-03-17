import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  final storage = const FlutterSecureStorage();
  final String baseUrl = 'https://api.emplbee.com';
  final AuthService _authService = AuthService();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  Future<UserModel> getCurrentUser() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // First try to get user info from Auth0
      final auth0Response = await http.get(
        Uri.parse('https://emplbee.uk.auth0.com/userinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (auth0Response.statusCode != 200) {
        throw Exception(
            'Failed to get user info from Auth0: ${auth0Response.body}');
      }

      final auth0Data = json.decode(auth0Response.body);

      // Then get additional user data from your backend
      final backendResponse = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (backendResponse.statusCode != 200) {
        throw Exception(
            'Failed to get user profile from backend: ${backendResponse.body}');
      }

      final backendData = json.decode(backendResponse.body);

      // Combine data from both sources
      return UserModel(
        id: backendData['id'] ?? '',
        auth_id: auth0Data['sub'] ?? '',
        email: auth0Data['email'] ?? '',
        username: backendData['username'] ?? auth0Data['nickname'] ?? '',
        createdAt:
            backendData['created_at'] ?? DateTime.now().toIso8601String(),
        updatedAt:
            backendData['updated_at'] ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }
}
