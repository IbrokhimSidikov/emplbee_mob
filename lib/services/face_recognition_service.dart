import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FaceRecognitionService {
  final String apiKey;

  FaceRecognitionService(this.apiKey);

  Future<bool> checkInWithFaceRecognition(
      String imagePath, String personId) async {
    final url = 'https://api.luxand.cloud/photo/verify/b50d5157-27d6-11ef-86d3-0242ac120002';
    final headers = {
      'token': apiKey,
    };
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: 'image.jpg',
      ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Response status: ${response.statusCode}');
    print('Response body: $responseBody');

    if (response.statusCode == 200) {
      final result = json.decode(responseBody);
      if (result['status'] == 'success') {
        // print('Face similarity: ${result['similarity']}');
        return true;
      } else {
        // print('Verification failed: ${result['error_message']}');
        return false;
      }
    } else {
      print('Error verifying face: ${response.reasonPhrase}');
      return false;
    }
  }
}
