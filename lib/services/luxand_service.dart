import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class LuxandService {
  final String apiUrl = 'https://api.luxand.cloud/photo/verify/';
  final String apiToken = '719876f955a84032a0e25193c4f103e2';

  Future<Map<String, dynamic>> verifyPerson(String uuid, File photo) async {
    final url = Uri.parse('$apiUrl$uuid');
    final headers = {
      'token': apiToken,
    };
    final imageBytes = await photo.readAsBytes();

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: 'photo.jpg',
      ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to verify face: ${response.reasonPhrase}');
    }
  }
}
