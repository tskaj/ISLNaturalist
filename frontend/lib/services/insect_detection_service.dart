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

  // For mobile platforms with authentication
  static Future<Map<String, dynamic>> detectInsectSpecies(
    File imageFile, 
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    // Add the file to the request
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Insect detection response: $responseData");
        return _processInsectResponse(responseData);
      } else {
        print("Insect detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect insect: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during insect detection: $e");
      throw Exception('Error detecting insect: $e');
    }
  }
  
  // For web platforms with authentication
  static Future<Map<String, dynamic>> detectInsectSpeciesWeb(
    Uint8List imageBytes,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    // Add the file to the request
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Insect detection response: $responseData");
        return _processInsectResponse(responseData);
      } else {
        print("Insect detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect insect: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during insect detection: $e");
      throw Exception('Error detecting insect: $e');
    }
  }
  
  // For anonymous users (mobile)
  static Future<Map<String, dynamic>> detectInsectSpeciesAnonymous(
    File imageFile,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    // Add the file to the request
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Insect detection response: $responseData");
        return _processInsectResponse(responseData);
      } else {
        print("Insect detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect insect: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during insect detection: $e");
      throw Exception('Error detecting insect: $e');
    }
  }
  
  // For anonymous users (web)
  static Future<Map<String, dynamic>> detectInsectSpeciesAnonymousWeb(
    Uint8List imageBytes,
  ) async {
    final url = Uri.parse('$baseUrl/api/insects/detect-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    // Add the file to the request
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Insect detection response: $responseData");
        return _processInsectResponse(responseData);
      } else {
        print("Insect detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect insect: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during insect detection: $e");
      throw Exception('Error detecting insect: $e');
    }
  }
  
  // Process API response to create a unified insect data structure
  static Map<String, dynamic> _processInsectResponse(Map<String, dynamic> apiResponse) {
    try {
      print("Processing insect response: $apiResponse");
      
      // Handle the format with 'predictions' array
      if (apiResponse.containsKey('predictions') && apiResponse['predictions'] is List && apiResponse['predictions'].isNotEmpty) {
        final topPrediction = apiResponse['predictions'][0];
        
        return {
          'insect_name': topPrediction['class'] ?? 'Unknown Insect',
          'confidence': topPrediction['confidence'] ?? 0.0,
          'description': _getInsectDescription(topPrediction['class']),
          'is_harmful': _isInsectHarmful(topPrediction['class']),
          'common_locations': _getInsectLocations(topPrediction['class']),
          'additional_info': _getInsectAdditionalInfo(topPrediction['class']),
        };
      } 
      // Handle the alternative format with 'success', 'species', and 'detections' fields
      else if (apiResponse.containsKey('success') && apiResponse['success'] == true) {
        String insectClass = apiResponse['species'] ?? 'Unknown Insect';
        double confidence = apiResponse['confidence'] ?? 0.0;
        
        // If there are detections available, use the first one
        if (apiResponse.containsKey('detections') && 
            apiResponse['detections'] is List && 
            apiResponse['detections'].isNotEmpty) {
          
          final detection = apiResponse['detections'][0];
          // Override with detection data if available
          insectClass = detection['class'] ?? insectClass;
          confidence = detection['confidence'] ?? confidence;
        }
        
        return {
          'insect_name': insectClass,
          'confidence': confidence,
          'description': _getInsectDescription(insectClass),
          'is_harmful': _isInsectHarmful(insectClass),
          'common_locations': _getInsectLocations(insectClass),
          'additional_info': _getInsectAdditionalInfo(insectClass),
        };
      } 
      else {
        print("Unexpected API response format: $apiResponse");
        return {
          'insect_name': 'Unknown Insect',
          'confidence': 0.0,
          'description': 'No information available',
          'is_harmful': false,
          'common_locations': 'Unknown',
          'additional_info': 'No additional information available',
        };
      }
    } catch (e) {
      print("Error processing insect response: $e");
      return {
        'insect_name': 'Error',
        'confidence': 0.0,
        'description': 'Error processing detection result',
        'is_harmful': false,
        'common_locations': 'Unknown',
        'additional_info': 'An error occurred while processing the detection result.',
      };
    }
  }
  
  // Helper method to get insect description based on class
  static String _getInsectDescription(String? insectClass) {
    if (insectClass == null) return 'No description available';
    
    final normalizedClass = insectClass.toLowerCase();
    
    switch (normalizedClass) {
      case 'lepi':
      case 'lepidoptera':
        return 'Lepidoptera is an order of insects that includes butterflies and moths. They are characterized by their large, often colorful wings covered with tiny scales. Most species have a proboscis (elongated mouthpart) used for feeding on nectar.';
      case 'ant':
        return 'Ants are social insects that form colonies with complex organizational structures. They are known for their cooperative behavior and ability to carry objects many times their own weight.';
      case 'bee':
        return 'Bees are flying insects known for their role in pollination and, in the case of honey bees, for producing honey and beeswax. They are vital to healthy ecosystems and agriculture.';
      case 'beetle':
        return 'Beetles are insects with hardened forewings that protect their hindwings. They comprise the largest order of insects and inhabit almost every type of habitat.';
      case 'butterfly':
        return 'Butterflies are day-flying insects with large, often brightly colored wings. They have a four-stage life cycle: egg, larva (caterpillar), pupa (chrysalis), and adult.';
      case 'dragonfly':
        return 'Dragonflies are predatory insects characterized by their large multifaceted eyes, two pairs of strong transparent wings, and elongated bodies. They are agile fliers.';
      case 'grasshopper':
        return 'Grasshoppers are plant-eating insects with powerful hind legs that allow them to escape from threats by leaping. They can also produce sounds by rubbing their legs against their wings.';
      case 'ladybug':
        return 'Ladybugs (or ladybirds) are small, spotted beetles that are usually red with black spots. They are beneficial insects as they eat plant-eating insects like aphids.';
      case 'mosquito':
        return 'Mosquitoes are small, flying insects with long, slender bodies and a pair of wings. Female mosquitoes feed on blood from various hosts, while males feed on nectar.';
      case 'spider':
        return 'Spiders are arachnids, not insects, characterized by eight legs and the ability to produce silk. Most are predatory, using webs to catch prey or actively hunting.';
      case 'wasp':
        return 'Wasps are flying insects with a narrow waist, a stinger, and typically a bright yellow and black pattern. Many are predatory or parasitic on other insects.';
      default:
        return 'This appears to be a ${insectClass.toLowerCase()}. Further information is not available in our database.';
    }
  }
  
  // Helper method to determine if an insect is harmful
  static bool _isInsectHarmful(String? insectClass) {
    if (insectClass == null) return false;
    
    final normalizedClass = insectClass.toLowerCase();
    
    switch (normalizedClass) {
      case 'lepi':
      case 'lepidoptera':
        return false; // Most lepidoptera as adults are not harmful, though some caterpillars can be
      case 'mosquito':
      case 'wasp':
        return true;
      case 'ant':
        return false; // Most ants are considered neutral or beneficial
      case 'bee':
        return false; // Bees are beneficial despite potential for stings
      case 'ladybug':
        return false; // Ladybugs are beneficial predators
      default:
        return false; // Default to non-harmful if not specifically categorized
    }
  }
  
  // Helper method to get common locations for insects
  static String _getInsectLocations(String? insectClass) {
    if (insectClass == null) return 'Unknown';
    
    final normalizedClass = insectClass.toLowerCase();
    
    switch (normalizedClass) {
      case 'lepi':
      case 'lepidoptera':
        return 'Worldwide in various habitats including forests, meadows, gardens, and agricultural areas. Different species adapt to specific environments.';
      case 'ant':
        return 'Gardens, forests, fields, and human dwellings worldwide';
      case 'bee':
        return 'Gardens, forests, meadows, and agricultural areas with flowering plants';
      case 'beetle':
        return 'Virtually all terrestrial and freshwater habitats worldwide';
      case 'butterfly':
        return 'Gardens, meadows, forests, and other areas with flowering plants';
      case 'dragonfly':
        return 'Near freshwater bodies like ponds, lakes, and streams';
      case 'grasshopper':
        return 'Grasslands, meadows, agricultural fields, and open woodland areas';
      case 'ladybug':
        return 'Gardens, fields, and forests worldwide';
      case 'mosquito':
        return 'Near standing water in both rural and urban environments';
      case 'spider':
        return 'Almost all terrestrial habitats worldwide';
      case 'wasp':
        return 'Gardens, forests, fields, and human dwellings in most regions';
      default:
        return 'Specific location information is not available in our database';
    }
  }
  
  // Helper method to get additional info for insects
  static String _getInsectAdditionalInfo(String? insectClass) {
    if (insectClass == null) return 'No additional information available';
    
    final normalizedClass = insectClass.toLowerCase();
    
    switch (normalizedClass) {
      case 'lepi':
      case 'lepidoptera':
        return 'Lepidoptera undergo complete metamorphosis with four life stages: egg, larva (caterpillar), pupa (chrysalis or cocoon), and adult. Butterflies are typically active during the day, while moths are mostly nocturnal. There are approximately 180,000 species of Lepidoptera.';
      case 'ant':
        return 'Ants communicate with each other using pheromones and can form colonies consisting of millions of individuals. They play important roles in soil aeration and seed dispersal.';
      case 'bee':
        return 'Bees are essential pollinators for many plants, including numerous food crops. Their populations have been declining in many regions, raising ecological concerns.';
      case 'beetle':
        return 'With over 400,000 species, beetles are the most diverse group of organisms on Earth. They play various ecological roles as decomposers, predators, and herbivores.';
      case 'butterfly':
        return 'Butterflies are important pollinators and indicators of ecosystem health. The Monarch butterfly is known for its remarkable long-distance migration.';
      case 'dragonfly':
        return 'Dragonflies are excellent indicators of water quality and can live for several years as aquatic nymphs before transforming into the adult flying form.';
      case 'grasshopper':
        return 'Grasshoppers can jump up to 20 times their body length and are an important food source for many birds, reptiles, and mammals.';
      case 'ladybug':
        return 'A single ladybug can eat up to 5,000 aphids in its lifetime, making them valuable for natural pest control in gardens and agriculture.';
      case 'mosquito':
        return 'While mosquitoes can transmit diseases, they also serve as important food sources for many animals and their larvae help filter water bodies of microorganisms.';
      case 'spider':
        return 'Most spiders produce silk, which they use for web construction, prey capture, shelter, reproduction, and dispersal. They are beneficial predators that help control pest populations.';
      case 'wasp':
        return 'Despite their fearsome reputation, many wasps are beneficial predators of pest insects. Some parasitic wasps are used as biological control agents in agriculture.';
      default:
        return 'Further information about this insect is not available in our database at this time.';
    }
  }
  
  // Helper method to pick an image from gallery or camera
  static Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(source: source);
  }
}