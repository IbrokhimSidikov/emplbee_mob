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
      print('Auth0 Profile Data: $auth0Data'); // Debug log

      // Then get additional user data from your backend
      final backendResponse = await http.get(
        Uri.parse('$baseUrl/v1/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          'Backend Response Status: ${backendResponse.statusCode}'); // Debug log
      print('Backend Response Body: ${backendResponse.body}'); // Debug log

      if (backendResponse.statusCode == 200) {
        final backendData = json.decode(backendResponse.body);
        print('Backend Profile Data: $backendData'); // Debug log

        // Merge Auth0 and backend data
        final Map<String, dynamic> mergedData = {
          ...Map<String, dynamic>.from(auth0Data),
          ...Map<String, dynamic>.from(backendData),
          'auth_id': auth0Data['sub'],
          'email': auth0Data['email'],
          'username': backendData['username'] ??
              auth0Data['nickname'] ??
              auth0Data['email']?.split('@')[0],
          'name': backendData['name'] ??
              auth0Data['name'] ??
              auth0Data['email']?.split('@')[0],
          'photo': backendData['photo'] ?? auth0Data['picture'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        return UserModel.fromJson(mergedData);
      } else {
        // If backend fails, use Auth0 data only
        print('Using Auth0 data only due to backend error');
        final Map<String, dynamic> basicData = {
          'id': auth0Data['sub'],
          'auth_id': auth0Data['sub'],
          'email': auth0Data['email'],
          'username':
              auth0Data['nickname'] ?? auth0Data['email']?.split('@')[0],
          'name': auth0Data['name'],
          'photo': auth0Data['picture'],
          'position': null,
          'phone': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        return UserModel.fromJson(basicData);
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      rethrow;
    }
  }
}
