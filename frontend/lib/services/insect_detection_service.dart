import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class InsectDetectionService {
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
  static Future<Map<String, dynamic>> detectInsectSpecies(
    File imageFile, 
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    // Add the image file to the request
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect insect species: ${response.statusCode}',
      };
    }
  }
  
  // For web platforms
  static Future<Map<String, dynamic>> detectInsectSpeciesWeb(
    Uint8List imageBytes, 
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    // Add the image bytes to the request
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect insect species: ${response.statusCode}',
      };
    }
  }
  
  // For anonymous users (mobile)
  static Future<Map<String, dynamic>> detectInsectSpeciesAnonymous(
    File imageFile,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    // Add the image file to the request
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect insect species: ${response.statusCode}',
      };
    }
  }
  
  // For anonymous users (web)
  static Future<Map<String, dynamic>> detectInsectSpeciesAnonymousWeb(
    Uint8List imageBytes,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    // Add the image bytes to the request
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect insect species: ${response.statusCode}',
      };
    }
  }
  
  // Helper method to pick an image from gallery or camera
  static Future<XFile?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    return image;
  }
}