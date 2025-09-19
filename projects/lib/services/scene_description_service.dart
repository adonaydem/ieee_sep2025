import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:projects/services/auth_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SceneDescriptionService {


  Future<String> sendImageForSD(String imagePath) async {
    String? uri = dotenv.env['BACKEND'];
  if (uri == null) {
      print("!!!!!!!!!!!!!!!!!API not found");
      return "";
  }
  final url = Uri.parse(uri+'/sd'); // Replace with your Flask server IP
  final imageFile = File(imagePath);

  try {
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      return data['text'] ?? '';
    } else {
      throw Exception('Failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    print( 'Error: $e');
    return "";
  }
}
  
}