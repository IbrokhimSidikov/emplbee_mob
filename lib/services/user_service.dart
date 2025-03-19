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

  Future<Map<String, dynamic>> _fetchAuth0Profile(String token) async {
    final response = await http.get(
      Uri.parse('https://emplbee.uk.auth0.com/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get Auth0 profile: ${response.body}');
    }

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _fetchBackendProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get backend profile: ${response.body}');
    }

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _fetchUserConfig(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/config'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get user config: ${response.body}');
    }

    return json.decode(response.body);
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // Fetch all user data in parallel
      final results = await Future.wait([
        _fetchAuth0Profile(token),
        _fetchBackendProfile(token),
        _fetchUserConfig(token),
      ]);

      final auth0Data = results[0];
      final backendData = results[1];
      final configData = results[2];

      // Merge all data sources
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
        'member_id': configData['memberId'],
        'organization_id': configData['organizationId'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Cache the user data
      await storage.write(
        key: 'user_data',
        value: json.encode(mergedData),
      );

      return UserModel.fromJson(mergedData);
    } catch (e) {
      // Try to get cached user data if network request fails
      final cachedData = await storage.read(key: 'user_data');
      if (cachedData != null) {
        return UserModel.fromJson(json.decode(cachedData));
      }
      print('Error in getCurrentUser: $e');
      rethrow;
    }
  }
}
