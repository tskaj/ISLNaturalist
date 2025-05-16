import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BirdDetectionService {
  // Get base URL from environment variables
  static String getBaseUrl() {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    } catch (e) {
      print("Error accessing environment variables: $e");
      return 'http://localhost:8000';
    }
  }
  
  static final String baseUrl = getBaseUrl();

  // For mobile platforms
  static Future<Map<String, dynamic>> detectBirdSpecies(
    File imageFile, 
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/birds/detect/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      // Try to parse error message
      try {
        final errorData = json.decode(responseData);
        throw Exception(errorData['error'] ?? 'Failed to detect bird species');
      } catch (e) {
        throw Exception('Failed to detect bird species: ${response.statusCode}');
      }
    }
  }

  // For anonymous detection (no token required)
  static Future<Map<String, dynamic>> detectBirdSpeciesAnonymous(
    File imageFile,
  ) async {
    final url = Uri.parse('$baseUrl/api/birds/detect-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      // Try to parse error message
      try {
        final errorData = json.decode(responseData);
        throw Exception(errorData['error'] ?? 'Failed to detect bird species');
      } catch (e) {
        throw Exception('Failed to detect bird species: ${response.statusCode}');
      }
    }
  }

  // Helper method to pick an image from gallery or camera
  static Future<File?> pickImage({bool fromCamera = false}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Reduce image quality to save bandwidth
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  static detectBirdSpeciesWeb(Uint8List bytes, String token) {}

  static detectInsectSpeciesAnonymousWeb(Uint8List bytes) {}
}