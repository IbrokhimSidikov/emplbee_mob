import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _clientId = 'XdNYrYSqdeGXenQPeMJhwfyu1J0pD1MA';
  static const String _domain = 'emplbee.uk.auth0.com';
  static const String _androidCallbackUri = 'appemplbee://callback';
  static const String _audience = 'https://emplbee.uk.auth0.com/api/v2/';
  static const String _iosCallbackUri = 'appemplbee://callback';
  static const String _callbackScheme = 'appemplbee';
  static const String _logoutCallbackUri = 'appemplbee://logout-callback';
  final String callbackScheme = _callbackScheme;
  final storage = FlutterSecureStorage();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _idTokenKey = 'id_token';
  static const String _userProfileKey = 'user_profile';
  static const String _tokenExpiryKey = 'token_expiry';

  Future<bool> login() async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      final url = Uri.https(_domain, '/authorize', {
        'response_type': 'code',
        'client_id': _clientId,
        'redirect_uri': callbackUri(),
        'scope': 'openid profile email offline_access',
        'audience': _audience,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        'prompt': 'login'
      }).toString();

      await storage.write(key: '_code_verifier', value: codeVerifier);
      await storage.write(key: '_state', value: state);

      print('Auth URL: $url'); // Debug log
      print('Callback URI: ${callbackUri()}'); // Debug log

      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: _callbackScheme,
      );

      print('Auth Result: $result'); // Debug log

      final resultUri = Uri.parse(result);
      final code = resultUri.queryParameters['code'];
      print('Authorization Code: $code'); // Debug log

      final resultState = resultUri.queryParameters['state'];
      final error = resultUri.queryParameters['error'];
      final errorDescription = resultUri.queryParameters['error_description'];

      if (error != null) {
        print('Auth0 Error: $error - $errorDescription');
        return false;
      }

      final storedState = await storage.read(key: '_state');
      if (resultState != storedState) {
        print('State mismatch: $resultState != $storedState');
        return false;
      }

      if (code == null) {
        print('No authorization code received');
        return false;
      }

      await _exchangeCodeForTokens(code);
      print('Tokens exchanged successfully'); // Debug log

      final accessToken = await getAccessToken();
      print('Access Token after login: $accessToken'); // Debug log

      await _fetchAndStoreUserProfile();
      return true;
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('CANCELED') ||
          e.toString().contains('canceled')) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    print('Exchanging code for tokens...'); // Debug log
    final codeVerifier = await storage.read(key: '_code_verifier');
    if (codeVerifier == null) throw Exception('Code verifier not found');

    final response = await http.post(
      Uri.parse('https://$_domain/oauth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'code_verifier': codeVerifier,
        'code': code,
        'redirect_uri': callbackUri(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange code for tokens: ${response.body}');
    }

    final tokens = jsonDecode(response.body);
    print('Received tokens from Auth0:'); // Debug log
    print('Access Token: ${tokens['access_token']}'); // Debug log
    print('Token Type: ${tokens['token_type']}'); // Debug log
    print('Expires In: ${tokens['expires_in']} seconds'); // Debug log
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

  Future<List<String>> getUserPermissions() async {
    final token = await getAccessToken();
    if (token == null) throw AuthException('No access token available');

    final response = await http.get(
      Uri.parse('YOUR_BACKEND_API/v1/user/permissions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['permissions'] ?? []);
    } else {
      await _handleError(response);
      return [];
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      // This matches your PHP backend token validation
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      // Check if token is expired
      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      if (DateTime.now().isAfter(expiry)) return false;

      // Check issuer matches your domain
      if (payload['iss'] != 'https://$_domain/') return false;

      // Check audience matches your clientId
      if (payload['aud'] != _clientId) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchConfig() async {
    final token = await getAccessToken();
    if (token == null) return null;

    print('Fetching config with token: $token'); // Debug log
    try {
      final response = await http.get(
        Uri.parse(
            'https://app.emplbee.com/api/v1/config?fields=memberId,organizationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Config Response Status: ${response.statusCode}'); // Debug log
      // print('Config Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final configData = jsonDecode(response.body);
        await storage.write(
            key: 'memberId', value: configData['memberId']?.toString());
        await storage.write(
            key: 'organizationId',
            value: configData['organizationId']?.toString());
        return {
          'memberId': configData['memberId'],
          'organizationId': configData['organizationId'],
        };
      }
      return null;
    } catch (e) {
      print('Error fetching config: $e');
      return null;
    }
  }

  Future<void> _fetchAndStoreUserProfile() async {
    final token = await getAccessToken();
    if (token == null) throw Exception('No access token available');

    // First fetch config to get member_id
    final configData = await _fetchConfig();
    print('Config Data: $configData'); // Debug log

    // Then get user info from Auth0
    final auth0Response = await http.get(
      Uri.parse('https://$_domain/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (auth0Response.statusCode != 200) {
      throw Exception('Failed to fetch Auth0 user profile');
    }

    final auth0Data = jsonDecode(auth0Response.body);
    print('Auth0 User Data: $auth0Data'); // Debug log

    try {
      final apiResponse = await http.get(
        Uri.parse('https://api.emplbee.com/v1/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (apiResponse.statusCode == 200) {
        final apiData = jsonDecode(apiResponse.body);
        print('Backend API User Data: $apiData'); // Debug log

        // Merge Auth0 data with your CRM data
        final Map<String, dynamic> mergedData = {
          ...Map<String, dynamic>.from(auth0Data),
          ...Map<String, dynamic>.from(apiData),
          'auth_id': auth0Data['sub'],
          'email': auth0Data['email'],
          'name': apiData['name'] ??
              auth0Data['name'] ??
              auth0Data['email']?.split('@')[0],
          'username': apiData['username'] ??
              auth0Data['nickname'] ??
              auth0Data['email']?.split('@')[0],
          'position': apiData['position'] ?? null,
          'phone': apiData['phone'] ?? null,
          'photo': apiData['photo'] ?? null,
          'member_id': configData?['member_id'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final user = UserModel.fromJson(mergedData);
        await storage.write(
            key: _userProfileKey, value: jsonEncode(user.toJson()));
      } else {
        // If backend API fails, still save Auth0 data
        final Map<String, dynamic> basicData = {
          'id': auth0Data['sub'],
          'auth_id': auth0Data['sub'],
          'email': auth0Data['email'],
          'username':
              auth0Data['nickname'] ?? auth0Data['email']?.split('@')[0],
          'name': auth0Data['name'],
          'position': null,
          'phone': null,
          'photo': null,
          'member_id': configData?['member_id'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final user = UserModel.fromJson(basicData);
        await storage.write(
            key: _userProfileKey, value: jsonEncode(user.toJson()));
      }
    } catch (e) {
      print('Error fetching backend profile: $e');
      // If backend API fails, still save Auth0 data
      final Map<String, dynamic> basicData = {
        'id': auth0Data['sub'],
        'auth_id': auth0Data['sub'],
        'email': auth0Data['email'],
        'username': auth0Data['nickname'] ?? auth0Data['email']?.split('@')[0],
        'name': auth0Data['name'],
        'position': null,
        'phone': null,
        'photo': null,
        'member_id': configData?['member_id'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final user = UserModel.fromJson(basicData);
      await storage.write(
          key: _userProfileKey, value: jsonEncode(user.toJson()));
    }
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
      Uri.parse('https://$_domain/oauth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'client_id': _clientId,
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
    final token = await storage.read(key: _accessTokenKey);
    print('Current Access Token: $token'); // Debug log
    return token;
  }

  Future<bool> updateMemberStatus(String status) async {
    final token = await getAccessToken();
    if (token == null) return false;
    print('Current Access Token: $token');
    final memberId = await storage.read(key: 'memberId');
    if (memberId == null) {
      print('No member ID found');
      return false;
    }

    try {
      print('\n=== Updating Member Status ===');
      print('Member ID: $memberId');
      print('New Status: $status');

      final requestBody = {
        'id': memberId,
        'attendanceStatus': status,
      };
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.patch(
        Uri.parse('https://app.emplbee.com/api/v1/member'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('\n=== Response Details ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('========================\n');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating member status: $e');
      return false;
    }
  }

  Future<String?> getMemberId() async {
    return await storage.read(key: 'memberId');
  }

  Future<String?> getOrganizationId() async {
    return await storage.read(key: 'organizationId');
  }

  Future<void> logout() async {
    try {
      print('Logout: Starting logout process');
      final idToken = await storage.read(key: _idTokenKey);
      print(
          'Logout: Retrieved ID token ${idToken != null ? '(found)' : '(not found)'}');

      // Construct Auth0 logout URL
      final logoutUrl = Uri.https(_domain, '/v2/logout', {
        'client_id': _clientId,
        'returnTo': _logoutCallbackUri,
        if (idToken != null) 'id_token_hint': idToken,
      }).toString();
      print('Logout: Constructed logout URL: $logoutUrl');

      // Clear tokens from secure storage
      print('Logout: Clearing secure storage');
      await storage.deleteAll();
      print('Logout: Secure storage cleared');

      // Redirect to Auth0 logout endpoint
      print('Logout: Redirecting to Auth0 logout endpoint');
      await FlutterWebAuth2.authenticate(
        url: logoutUrl,
        callbackUrlScheme: _callbackScheme,
      );
      print('Logout: Successfully logged out from Auth0');
    } catch (e) {
      print('Logout error: $e');
      // Even if Auth0 logout fails, ensure local tokens are cleared
      print('Logout: Clearing secure storage after error');
      await storage.deleteAll();
      rethrow;
    }
  }

  String callbackUri() {
    return Platform.isAndroid ? _androidCallbackUri : _iosCallbackUri;
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    final user = await getUserProfile();
    return token != null && user != null;
  }
}

class AuthError {
  final String code;
  final String message;

  AuthError.fromJson(Map<String, dynamic> json)
      : code = json['statusCode']?.toString() ?? '500',
        message = json['message'] ?? 'Unknown error';
}

Future<void> _handleError(http.Response response) async {
  if (response.statusCode != 200) {
    final error = AuthError.fromJson(jsonDecode(response.body));
    throw AuthException('${error.code}: ${error.message}');
  }
}

String _generateCodeVerifier() {
  const length = 64;
  final random = Random.secure();
  final values = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url
      .encode(values)
      .replaceAll('=', '')
      .replaceAll('+', '-')
      .replaceAll('/', '_');
}

String _generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64Url
      .encode(digest.bytes)
      .replaceAll('=', '')
      .replaceAll('+', '-')
      .replaceAll('/', '_');
}

bool _isTokenValid(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    final payload = json
        .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

    final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    return DateTime.now().isBefore(expiry);
  } catch (e) {
    return false;
  }
}

Future<T> _handleNetworkRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on SocketException {
    throw AuthException('No internet connection');
  } on TimeoutException {
    throw AuthException('Request timed out');
  } catch (e) {
    throw AuthException('Network error: ${e.toString()}');
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

String _generateState() {
  final random = Random.secure();
  final values = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(values);
}

class ApiError {
  final String error;
  final String errorDescription;

  ApiError.fromJson(Map<String, dynamic> json)
      : error = json['error'],
        errorDescription = json['error_description'];
}
