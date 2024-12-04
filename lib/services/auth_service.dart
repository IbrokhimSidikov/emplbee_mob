import 'dart:io';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final String clientId = 'XdNYrYSqdeGXenQPeMJhwfyu1J0pD1MA';
  final String domain = 'emplbee.uk.auth0.com';
  final String androidCallbackUri = 'https://emplbee.uk.auth0.com/android/APPEMPLBEE/callback';
  final String iosCallbackUri = 'https://emplbee.uk.auth0.com/ios/com.emplbee.app/callback';
  final String callbackScheme = 'https';
  final storage = FlutterSecureStorage();

  Future<void> login() async {
    try {
      final url = 'https://$domain/authorize?'
          'audience=https://$domain/userinfo&'
          'scope=openid profile email offline_access&'
          'response_type=code&'
          'client_id=$clientId&'
          'redirect_uri=${callbackUri()}';

      print('Opening URL: $url');
      print('Callback URI: ${callbackUri()}');

      final result = await FlutterWebAuth2.authenticate(
          url: url, callbackUrlScheme: callbackScheme);

      print('Auth Result: $result');

      final code = Uri.parse(result).queryParameters['code'];
      print('Authorization code: $code');

      final tokenUrl = 'https://$domain/oauth/token';
      final body = {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': callbackUri(),
      };
      print('Token request URL: $tokenUrl');
      print('Token request body: $body');

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Token response status: ${response.statusCode}');
      print('Token response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Token request failed with status: ${response.statusCode}, body: ${response.body}');
      }

      final responseBody = jsonDecode(response.body);
      if (responseBody['access_token'] != null) {
        await storage.write(key: 'access_token', value: responseBody['access_token']);
        print('Access token stored successfully');
      } else {
        print('No access token in response');
        throw Exception('No access token in response');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  String callbackUri() {
    return Platform.isAndroid ? androidCallbackUri : iosCallbackUri;
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }
}
