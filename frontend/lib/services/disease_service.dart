import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DiseaseService {
  // In your DiseaseService class, update the getBaseUrl method:
  
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
  static Future<Map<String, dynamic>> detectDisease(
    File imageFile, 
    String token, 
    {String cropType = 'tomato'}
  ) async {
    // Use the classify-disease endpoint
    final url = Uri.parse('$baseUrl/api/disease/classify-disease/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return {
        'success': true,
        'data': jsonResponse['data'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Update other methods to use the correct endpoints
  
  // For web platforms
  static Future<Map<String, dynamic>> detectDiseaseWeb(
    Uint8List imageBytes, 
    String token,
    {String cropType = 'tomato'}
  ) async {
    // Use the classify-disease endpoint
    final url = Uri.parse('$baseUrl/api/disease/classify-disease/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return {
        'success': true,
        'data': jsonResponse['data'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Anonymous detection for mobile
  static Future<Map<String, dynamic>> detectDiseaseAnonymousMobile(
    File imageFile,
    {String cropType = 'tomato'}
  ) async {
    // Use the classify-disease endpoint
    final url = Uri.parse('$baseUrl/api/disease/classify-disease/');
    
    var request = http.MultipartRequest('POST', url);
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return {
        'success': true,
        'data': jsonResponse['data'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Anonymous detection for web
  static Future<Map<String, dynamic>> detectDiseaseAnonymousWeb(
    Uint8List imageBytes,
    {String cropType = 'tomato'}
  ) async {
    // Use the classify-disease endpoint
    final url = Uri.parse('$baseUrl/api/disease/classify-disease/');
    
    var request = http.MultipartRequest('POST', url);
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return {
        'success': true,
        'data': jsonResponse['data'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Get available crop types
  static Future<List<String>> getAvailableCrops(String? token) async {
    // You need to implement this endpoint in your Django backend
    // For now, return default values
    return ['tomato', 'apple', 'corn', 'potato', 'rice'];
  }
  
  // For mobile platforms - Pagdurusa disease classification model
  static Future<Map<String, dynamic>> classifyDiseasePagdurusa(
    File imageFile, 
    String? token
  ) async {
    final url = Uri.parse('$baseUrl/api/disease/classify-disease/');
    
    var request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
    ));
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData)['data'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to classify disease: ${response.statusCode}',
      };
    }
  }
  
  // For web platforms - Pagdurusa disease classification model
  static Future<Map<String, dynamic>> classifyDiseasePagdurusaWeb(
    Uint8List imageBytes, 
    String? token
  ) async {
    final url = Uri.parse('$baseUrl/api/disease/classify-disease/');
    
    var request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
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
        'data': json.decode(responseData)['data'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to classify disease: ${response.statusCode}',
      };
    }
  }
  
  // Validate if image is a leaf using Roboflow API
  static Future<Map<String, dynamic>> validateLeafImage(XFile image) async {
    try {
      // For web environment, we'll still use validation but with a different approach
      if (kIsWeb) {
        print('Web environment: performing validation check');
        
        // Get image bytes for validation
        Uint8List imageBytes;
        try {
          imageBytes = await image.readAsBytes();
        } catch (e) {
          print('Error reading web image bytes: $e');
          return {
            'isLeaf': false,
            'confidence': 0.0,
            'success': false,
            'message': 'Failed to read image data'
          };
        }
        
        // Call our backend validation endpoint instead of direct Roboflow API
        final validationUrl = Uri.parse('$baseUrl/api/disease/validate-leaf/');
        
        var request = http.MultipartRequest('POST', validationUrl);
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
        
        try {
          var response = await request.send();
          var responseData = await response.stream.bytesToString();
          
          if (response.statusCode == 200) {
            final data = json.decode(responseData);
            return {
              'isLeaf': data['is_leaf'] ?? false,
              'confidence': data['confidence'] ?? 0.0,
              'success': true
            };
          } else {
            print('Validation API error: ${response.statusCode}');
            // Don't default to true on API failure
            return {
              'isLeaf': false,
              'confidence': 0.0,
              'success': false,
              'message': 'Validation failed: ${response.statusCode}'
            };
          }
        } catch (e) {
          print('Exception during web validation: $e');
          return {
            'isLeaf': false,
            'confidence': 0.0,
            'success': false,
            'message': 'Validation error: $e'
          };
        }
      }
      
      // Roboflow API endpoint and key - using serverless endpoint as per documentation
      final roboflowApiUrl = 'https://serverless.roboflow.com/my-first-project-mxrml/1';
      final apiKey = dotenv.env['ROBOFLOW_API_KEY'] ?? 'xo6mQ5uBlOugUjY9G6ei';
      
      // Prepare the image data
      Uint8List imageBytes;
      try {
        if (image.path.isNotEmpty && !image.path.startsWith('blob:')) {
          // For mobile platforms
          imageBytes = await File(image.path).readAsBytes();
        } else {
          // For web platforms or when path is not available
          imageBytes = await image.readAsBytes();
        }
      } catch (e) {
        print('Error reading image bytes: $e');
        // If we can't read the image, allow it through with a warning
        return {
          'isLeaf': true,
          'confidence': 0.7,
          'success': true,
          'message': 'Skipped validation due to image reading error'
        };
      }
      
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      // Make API request - using the correct endpoint format
      final response = await http.post(
        Uri.parse('$roboflowApiUrl?api_key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'image': base64Image,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if the model identified a leaf with sufficient confidence
        // Based on Roboflow's classification model response format
        final predictions = data['predictions'] ?? [];
        
        if (predictions.isNotEmpty) {
          // Get the highest confidence prediction
          final highestConfidence = predictions.reduce((a, b) => 
            (a['confidence'] > b['confidence']) ? a : b);
          
          // Extract confidence as double (ensure proper type conversion)
          double confidence = 0.0;
          if (highestConfidence['confidence'] is double) {
            confidence = highestConfidence['confidence'];
          } else if (highestConfidence['confidence'] is int) {
            confidence = (highestConfidence['confidence'] as int).toDouble();
          } else if (highestConfidence['confidence'] is String) {
            confidence = double.tryParse(highestConfidence['confidence']) ?? 0.0;
          }
          
          return {
            'isLeaf': true,
            'confidence': confidence,
            'success': true
          };
        } else {
          return {
            'isLeaf': false,
            'confidence': 0.0,
            'success': true
          };
        }
      } else {
        print('Roboflow API error: ${response.statusCode} - ${response.body}');
        return {
          'isLeaf': true, // Default to true on API failure to avoid blocking users
          'success': false,
          'message': 'API request failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Exception during leaf validation: $e');
      return {
        'isLeaf': true, // Default to true on exception to avoid blocking users
        'success': false,
        'message': 'Error validating image: $e'
      };
    }
  }
}