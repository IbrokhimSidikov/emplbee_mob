import 'dart:io';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String clientId = 'XdNYrYSqdeGXenQPeMJhwfyu1J0pD1MA';
  final String domain = 'emplbee.uk.auth0.com';
  final String androidCallbackUri =
      'https://emplbee.uk.auth0.com/android/APPEMPLBEE/callback';
  final String iosCallbackUri =
      'https://emplbee.uk.auth0.com/ios/com.emplbee.app/callback';
  final String callbackScheme = 'com.emplbee.app';
  final storage = FlutterSecureStorage();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _idTokenKey = 'id_token';
  static const String _userProfileKey = 'user_profile';
  static const String _tokenExpiryKey = 'token_expiry';

  Future<bool> login() async {
    try {
      final url = 'https://$domain/authorize?'
          'audience=https://$domain/userinfo&'
          'scope=openid profile email offline_access&'
          'response_type=code&'
          'client_id=$clientId&'
          'redirect_uri=${callbackUri()}';

      final result = await FlutterWebAuth2.authenticate(
          url: url, callbackUrlScheme: callbackScheme);

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return false;

      await _exchangeCodeForTokens(code);
      await _fetchAndStoreUserProfile();
      return true;
    } catch (e) {
      print('Login error: $e');
      // Check if the error is due to user cancellation
      if (e.toString().contains('CANCELED') ||
          e.toString().contains('canceled')) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    final tokenUrl = 'https://$domain/oauth/token';
    final body = {
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'code': code,
      'redirect_uri': callbackUri(),
    };

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Token request failed with status: ${response.statusCode}, body: ${response.body}');
    }

    final tokens = jsonDecode(response.body);
    await _storeTokens(tokens);
  }

  Future<void> _storeTokens(Map<String, dynamic> tokens) async {
    if (tokens['access_token'] != null) {
      await storage.write(key: _accessTokenKey, value: tokens['access_token']);
    }
    if (tokens['refresh_token'] != null) {
      await storage.write(
          key: _refreshTokenKey, value: tokens['refresh_token']);
    }
    if (tokens['id_token'] != null) {
      await storage.write(key: _idTokenKey, value: tokens['id_token']);
    }
    if (tokens['expires_in'] != null) {
      final expiry =
          DateTime.now().add(Duration(seconds: tokens['expires_in']));
      await storage.write(
          key: _tokenExpiryKey, value: expiry.toIso8601String());
    }
  }

  Future<void> _fetchAndStoreUserProfile() async {
    final token = await getAccessToken();
    if (token == null) throw Exception('No access token available');

    final response = await http.get(
      Uri.parse('https://$domain/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user profile');
    }

    final userData = jsonDecode(response.body);
    final user = UserModel.fromJson(userData);
    await storage.write(key: _userProfileKey, value: jsonEncode(user.toJson()));
  }

  Future<bool> refreshTokenIfNeeded() async {
    try {
      final expiryStr = await storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return false;

      final expiry = DateTime.parse(expiryStr);
      if (expiry.isBefore(DateTime.now().add(Duration(minutes: 5)))) {
        await _refreshToken();
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking token expiry: $e');
      return false;
    }
  }

  Future<void> _refreshToken() async {
    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await http.post(
      Uri.parse('https://$domain/oauth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'refresh_token': refreshToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh token');
    }

    final tokens = jsonDecode(response.body);
    await _storeTokens(tokens);
  }

  Future<UserModel?> getUserProfile() async {
    try {
      final userJson = await storage.read(key: _userProfileKey);
      if (userJson == null) return null;
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    await refreshTokenIfNeeded();
    return await storage.read(key: _accessTokenKey);
  }

  Future<void> logout() async {
    // Revoke the refresh token on Auth0
    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (refreshToken != null) {
      try {
        await http.post(
          Uri.parse('https://$domain/oauth/revoke'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'client_id': clientId,
            'token': refreshToken,
          }),
        );
      } catch (e) {
        print('Error revoking refresh token: $e');
      }
    }

    // Clear all stored data
    await storage.deleteAll();
  }

  String callbackUri() {
    return Platform.isAndroid ? androidCallbackUri : iosCallbackUri;
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    final user = await getUserProfile();
    return token != null && user != null;
  }
}
