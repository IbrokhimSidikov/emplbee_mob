import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  final storage = const FlutterSecureStorage();
  final String baseUrl =
      'https://api.emplbee.com'; // Replace with your actual API URL

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  Future<UserModel> getCurrentUser() async {
    try {
      final token = await storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      // For development, return dummy data
      return UserModel(
        id: '1',
        name: 'Ibrokhim Sidikov',
        // position: 'Software Engineer',
        email: 'ibrokhim.sidikov@emplbee.com',
        // imageUrl: null, // Add your image URL here when available
        // workedHours: 160,
        // salary: 15000000,
        // availableOffDays: 15,
      );
    }
  }
}
