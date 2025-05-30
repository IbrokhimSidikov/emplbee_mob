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

  Future<UserModel> getCurrentUser() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // Get Auth0 profile for authentication
      final auth0Data = await _fetchAuth0Profile(token);

      // Get config data
      final configResponse = await http.get(
        Uri.parse('$baseUrl/v1/config'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (configResponse.statusCode != 200) {
        throw Exception('Failed to get config data: ${configResponse.body}');
      }

      final configData = json.decode(configResponse.body);
      print(
          'UserService: Received config data with name: ${configData['name']}');

      // Create user data prioritizing name from config
      final Map<String, dynamic> userData = {
        'id': auth0Data['sub'] ?? '',
        'auth_id': auth0Data['sub'],
        'email': auth0Data['email'],
        'username': auth0Data['nickname'] ?? auth0Data['email']?.split('@')[0],
        'name': configData['name'],
        'code': configData['code'],
        'type': configData['type'],
        'phone': configData['phone'],
        'photo': configData['photo'] ?? auth0Data['picture'],
        'memberId': configData['memberId']?.toString(),
        'organizationId': configData['organizationId']?.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      print('UserService: Created user data with name: ${userData['name']}');

      // Cache the user data
      await storage.write(
        key: 'user_profile',
        value: json.encode(userData),
      );

      return UserModel.fromJson(userData);
    } catch (e) {
      // Try to get cached user data if network request fails
      final cachedData = await storage.read(key: 'user_profile');
      if (cachedData != null) {
        return UserModel.fromJson(json.decode(cachedData));
      }
      print('Error in getCurrentUser: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMemberDetails(String memberId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse(
            'https://app.emplbee.com/api/v1/member/$memberId?expand=photo,team,position,attendances,activeTasks.status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get member details: ${response.body}');
      }

      final memberData = json.decode(response.body);
      print('UserService: Received member details for ID: $memberId');
      print('Member details: $memberData');
      return memberData;
    } catch (e) {
      print('Error in getMemberDetails: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMemberAttendances(
      String memberId, int page, int pageSize) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse(
            'https://app.emplbee.com/api/v1/member/$memberId/attendances?page=$page&per_page=$pageSize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get member attendances: ${response.body}');
      }

      final attendanceData = json.decode(response.body);
      print(
          'UserService: Received attendance data for member ID: $memberId, page: $page');
      return {'attendances': attendanceData['data'] ?? []};
    } catch (e) {
      print('Error in getMemberAttendances: $e');
      rethrow;
    }
  }
}
