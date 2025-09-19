import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/services/auth_service.dart';
// Make sure you import the file where doPreprocessing is defined
// import 'path/to/your/preprocessing_function.dart';
final authService = AuthService();
class TesseractTextRecognizer  {
  
  Future<String> sendImageForOcr(String imagePath) async {
    String? uri = dotenv.env['BACKEND'];
  if (uri == null) {
      print("!!!!!!!!!!!!!!!!!API not found");
      return "";
  }
  final url = Uri.parse(uri+'/ocr'); // Replace with your Flask server IP
  final imageFile = File(imagePath);
  
  try {
    String? uid = await authService.getCurrentUserId();

      if (uid == null) {
        throw Exception('User ID is null, please log in first');
      }

    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.fields['uid'] = uid;
    
    final response = await request.send();
    
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      return data['extracted_text'] ?? '';
    } else {
      throw Exception('Failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    print( 'Error: $e');
    return "";
  }
}

}

Future<String> refineOcrText(String rawText) async {
  String? url = dotenv.env['BACKEND'];
  if (url == null) {
      print("!!!!!!!!!!!!!!!!!API not found");
      return "";
  }
  final uri = Uri.parse(url! + '/refine_ocr'); // Replace with your actual backend address

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'text': rawText,
    },
  );

  if (response.statusCode == 200) {
    return response.body; // raw plain text returned
  } else {
    throw Exception('Failed to refine OCR: ${response.statusCode}');
  }
}


