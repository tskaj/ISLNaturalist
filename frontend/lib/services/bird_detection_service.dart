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

  // For mobile platforms with authentication
  static Future<Map<String, dynamic>> detectBirdSpecies(
    File imageFile, 
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/birds/detect/');
    
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
        print("Bird detection response: $responseData");
        return _processBirdResponse(responseData);
      } else {
        print("Bird detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect bird: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during bird detection: $e");
      throw Exception('Error detecting bird: $e');
    }
  }
  
  // For web platforms with authentication
  static Future<Map<String, dynamic>> detectBirdSpeciesWeb(
    Uint8List imageBytes,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/birds/detect/');
    
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
        print("Bird detection response: $responseData");
        return _processBirdResponse(responseData);
      } else {
        print("Bird detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect bird: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during bird detection: $e");
      throw Exception('Error detecting bird: $e');
    }
  }
  
  // For anonymous users (mobile)
  static Future<Map<String, dynamic>> detectBirdSpeciesAnonymous(
    File imageFile,
  ) async {
    final url = Uri.parse('$baseUrl/api/birds/detect-anonymous/');
    
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
        print("Bird detection response: $responseData");
        return _processBirdResponse(responseData);
      } else {
        print("Bird detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect bird: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during bird detection: $e");
      throw Exception('Error detecting bird: $e');
    }
  }
  
  // For anonymous users (web)
  static Future<Map<String, dynamic>> detectBirdSpeciesAnonymousWeb(
    Uint8List imageBytes,
  ) async {
    final url = Uri.parse('$baseUrl/api/birds/detect-anonymous/');
    
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
        print("Bird detection response: $responseData");
        return _processBirdResponse(responseData);
      } else {
        print("Bird detection error: ${response.statusCode} ${response.body}");
        throw Exception('Failed to detect bird: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during bird detection: $e");
      throw Exception('Error detecting bird: $e');
    }
  }
  
  // Process API response to create a unified bird data structure
  static Map<String, dynamic> _processBirdResponse(Map<String, dynamic> apiResponse) {
    try {
      print("Processing bird response: $apiResponse");
      
      // Handle the format with 'predictions' array
      if (apiResponse.containsKey('predictions') && apiResponse['predictions'] is List && apiResponse['predictions'].isNotEmpty) {
        final topPrediction = apiResponse['predictions'][0];
        
        return {
          'bird_name': topPrediction['class'] ?? 'Unknown Bird',
          'confidence': topPrediction['confidence'] ?? 0.0,
          'description': _getBirdDescription(topPrediction['class']),
          'habitat': _getBirdHabitat(topPrediction['class']),
          'is_migratory': _isBirdMigratory(topPrediction['class']),
          'diet': _getBirdDiet(topPrediction['class']),
          'additional_info': _getBirdAdditionalInfo(topPrediction['class']),
        };
      } 
      // Handle the alternative format with 'success', 'species', and 'detections' fields
      else if (apiResponse.containsKey('success') && apiResponse['success'] == true) {
        String birdClass = apiResponse['species'] ?? 'Unknown Bird';
        double confidence = apiResponse['confidence'] ?? 0.0;
        
        // If there are detections available, use the first one
        if (apiResponse.containsKey('detections') && 
            apiResponse['detections'] is List && 
            apiResponse['detections'].isNotEmpty) {
          
          final detection = apiResponse['detections'][0];
          // Override with detection data if available
          birdClass = detection['class'] ?? birdClass;
          confidence = detection['confidence'] ?? confidence;
        }
        
        return {
          'bird_name': birdClass,
          'confidence': confidence,
          'description': _getBirdDescription(birdClass),
          'habitat': _getBirdHabitat(birdClass),
          'is_migratory': _isBirdMigratory(birdClass),
          'diet': _getBirdDiet(birdClass),
          'additional_info': _getBirdAdditionalInfo(birdClass),
        };
      } 
      else {
        print("Unexpected API response format: $apiResponse");
        return {
          'bird_name': 'Unknown Bird',
          'confidence': 0.0,
          'description': 'No information available',
          'habitat': 'Unknown',
          'is_migratory': false,
          'diet': 'Unknown',
          'additional_info': 'No additional information available',
        };
      }
    } catch (e) {
      print("Error processing bird response: $e");
      return {
        'bird_name': 'Error',
        'confidence': 0.0,
        'description': 'Error processing detection result',
        'habitat': 'Unknown',
        'is_migratory': false,
        'diet': 'Unknown',
        'additional_info': 'An error occurred while processing the detection result.',
      };
    }
  }
  
  // Helper method to get bird description based on class
  static String _getBirdDescription(String? birdClass) {
    if (birdClass == null) return 'No description available';
    
    final normalizedClass = birdClass.toUpperCase();
    
    switch (normalizedClass) {
      case 'ALEXANDRINE PARAKEET':
        return 'The Alexandrine Parakeet is a large parrot with vibrant green plumage, a red patch on the shoulders, and a rose-pink band on the nape. Males have a distinctive black and rose-colored ring around their necks. These birds are known for their intelligence and ability to mimic human speech.';
      case 'GOLDEN EAGLE':
        return 'The Golden Eagle is one of the most impressive birds of prey with a wingspan of up to 7.5 feet. These majestic birds have dark brown plumage with lighter golden-brown feathers on the head and neck.';
      case 'BALD EAGLE':
        return 'The Bald Eagle is a symbol of the United States, recognized by its white head and tail contrasting with its dark brown body. They have powerful yellow beaks and talons.';
      case 'AMERICAN ROBIN':
        return 'The American Robin is a migratory songbird of the thrush family with a reddish-orange breast, dark head, and yellow bill. They\'re common across North America and are often seen hopping on lawns.';
      case 'BLUE JAY':
        return 'The Blue Jay is a striking bird with bright blue, white, and black plumage. They have a distinctive blue crest on their head that raises when excited or aggressive.';
      case 'CARDINAL':
        return 'The Northern Cardinal is known for its bright red coloration (in males), crest, and strong beak. Females are more brownish with some red accents. They\'re common songbirds in eastern and central North America.';
      case 'AMERICAN CROW':
        return 'The American Crow is an all-black bird with a fan-shaped tail and a harsh "caw" call. They\'re intelligent birds known for problem-solving abilities and complex social structures.';
      case 'BARN OWL':
        return 'The Barn Owl has a distinctive heart-shaped facial disk, buff-colored upper parts, and white underparts. They hunt primarily at night using their exceptional hearing abilities.';
      case 'RUBY-THROATED HUMMINGBIRD':
        return 'The Ruby-throated Hummingbird is tiny with emerald green back and crown, and males have a brilliant ruby-red throat patch. They can hover in mid-air and are the only hummingbird species that breeds in eastern North America.';
      case 'CANADA GOOSE':
        return 'The Canada Goose is a large wild goose with a black head and neck, white cheeks, and brown body. They\'re known for their V-formation during migration and their distinctive honking calls.';
      case 'GREAT BLUE HERON':
        return 'The Great Blue Heron is a large wading bird with bluish-gray plumage, a white face, and a yellow bill. They stand motionless in shallow water waiting to strike at fish with their long, sharp bills.';
      default:
        return 'This appears to be a $birdClass. Further information is not available in our database.';
    }
  }
  
  // Helper method to determine if a bird is migratory
  static bool _isBirdMigratory(String? birdClass) {
    if (birdClass == null) return false;
    
    final normalizedClass = birdClass.toUpperCase();
    
    switch (normalizedClass) {
      case 'ALEXANDRINE PARAKEET':
        return false; // Non-migratory
      case 'AMERICAN ROBIN':
      case 'RUBY-THROATED HUMMINGBIRD':
      case 'CANADA GOOSE':
        return true;
      case 'GOLDEN EAGLE':
        return true; // Some populations migrate
      case 'BLUE JAY':
        return false; // Some migrate, but most are residents
      case 'CARDINAL':
        return false; // Non-migratory
      case 'BALD EAGLE':
        return false; // Some regional movements, but not true migration
      default:
        return false; // Default if unknown
    }
  }
  
  // Helper method to get common habitats for birds
  static String _getBirdHabitat(String? birdClass) {
    if (birdClass == null) return 'Unknown';
    
    final normalizedClass = birdClass.toUpperCase();
    
    switch (normalizedClass) {
      case 'ALEXANDRINE PARAKEET':
        return 'Forests, woodlands, mangrove forests, and cultivated areas like orchards and farmlands. Often found in semi-open landscapes with trees for nesting.';
      case 'GOLDEN EAGLE':
        return 'Open and mountainous regions, tundra, coniferous forests, and grasslands';
      case 'BALD EAGLE':
        return 'Near large bodies of water with abundant food supply and old-growth trees for nesting';
      case 'AMERICAN ROBIN':
        return 'Woodlands, gardens, parks, yards, and agricultural areas';
      case 'BLUE JAY':
        return 'Deciduous and coniferous forests, woodland edges, and suburban areas';
      case 'CARDINAL':
        return 'Shrubby areas, forest edges, gardens, and suburban landscapes';
      case 'AMERICAN CROW':
        return 'Wide range of habitats including forests, fields, agricultural lands, and urban areas';
      case 'BARN OWL':
        return 'Open countryside, farmland, barns, church towers, and abandoned buildings';
      case 'RUBY-THROATED HUMMINGBIRD':
        return 'Gardens, woodland edges, meadows, and orchards with flowering plants';
      case 'CANADA GOOSE':
        return 'Lakes, rivers, ponds, parks, and grassy fields';
      case 'GREAT BLUE HERON':
        return 'Wetlands, marshes, ponds, lakes, rivers, and coastal areas';
      default:
        return 'Specific habitat information is not available in our database';
    }
  }
  
  // Helper method to get diet information for birds
  static String _getBirdDiet(String? birdClass) {
    if (birdClass == null) return 'Unknown';
    
    final normalizedClass = birdClass.toUpperCase();
    
    switch (normalizedClass) {
      case 'ALEXANDRINE PARAKEET':
        return 'Seeds, nuts, fruits, berries, blossoms, and leaf buds. They particularly enjoy ripening fruits and grains in agricultural areas.';
      case 'GOLDEN EAGLE':
        return 'Medium-sized mammals like rabbits and hares, also birds, reptiles, and carrion';
      case 'BALD EAGLE':
        return 'Fish is the primary diet, supplemented with waterfowl, small mammals, and carrion';
      case 'AMERICAN ROBIN':
        return 'Earthworms, insects, berries, and fruits';
      case 'BLUE JAY':
        return 'Nuts, seeds, insects, small vertebrates, and occasionally eggs or nestlings of other birds';
      case 'CARDINAL':
        return 'Seeds, fruits, grains, and insects';
      case 'AMERICAN CROW':
        return 'Omnivorous diet including insects, seeds, fruits, small animals, eggs, carrion, and human food scraps';
      case 'BARN OWL':
        return 'Small mammals, particularly rodents like mice, voles, and shrews';
      case 'RUBY-THROATED HUMMINGBIRD':
        return 'Nectar from flowers and small insects and spiders';
      case 'CANADA GOOSE':
        return 'Grasses, sedges, grains, and berries; grazes in fields and grassy areas';
      case 'GREAT BLUE HERON':
        return 'Fish, amphibians, reptiles, small mammals, and other small animals';
      default:
        return 'Specific diet information is not available in our database';
    }
  }
  
  // Helper method to get additional info for birds
  static String _getBirdAdditionalInfo(String? birdClass) {
    if (birdClass == null) return 'No additional information available';
    
    final normalizedClass = birdClass.toUpperCase();
    
    switch (normalizedClass) {
      case 'ALEXANDRINE PARAKEET':
        return 'Named after Alexander the Great, who is credited with bringing these birds from Asia to Europe. They can live up to 30 years in captivity. In the wild, they often form noisy flocks and are known for their powerful, direct flight with rapid wing beats.';
      case 'GOLDEN EAGLE':
        return 'Golden Eagles can dive at speeds over 150 mph when hunting. They mate for life and can live up to 30 years in the wild. Their nests (eyries) are enormous structures of sticks that pairs add to year after year.';
      case 'BALD EAGLE':
        return 'The Bald Eagle has been the national emblem of the United States since 1782. They can live up to 30 years in the wild, mate for life, and build the largest nest of any North American bird - up to 13 feet deep and 8 feet wide.';
      case 'AMERICAN ROBIN':
        return 'The American Robin is often viewed as a sign of spring in North America. They lay distinctive blue eggs and can produce three broods in one season. Their morning songs are a familiar sound in many neighborhoods.';
      case 'BLUE JAY':
        return 'Blue Jays are known for their intelligence and complex social systems. They can mimic the calls of hawks, often to warn other jays of danger or to deceive other birds. They\'re also known to cache food for later use.';
      case 'CARDINAL':
        return 'Cardinals don\'t migrate and don\'t molt into a dull plumage, so they\'re a splash of color in winter landscapes. Males actively defend their breeding territories from other males. Their distinctive crest can be raised and lowered.';
      case 'AMERICAN CROW':
        return 'Crows are among the most intelligent birds, capable of using tools, recognizing human faces, and engaging in complex play behavior. They live in family groups and have sophisticated communication systems.';
      case 'BARN OWL':
        return 'Barn Owls have asymmetrical ear placement which helps them pinpoint prey by sound alone. They can capture prey in complete darkness. They produce no audible wing beat when flying, allowing for silent hunting.';
      case 'RUBY-THROATED HUMMINGBIRD':
        return 'These tiny birds beat their wings about 53 times per second and can fly backward. They migrate across the Gulf of Mexico - a 500-mile journey over water that takes about 20 hours of non-stop flying.';
      case 'CANADA GOOSE':
        return 'Canada Geese form lifelong pair bonds and families stay together during migration. Their distinctive V-formation flight helps them conserve energy, with each bird flying slightly above the bird in front, reducing wind resistance.';
      case 'GREAT BLUE HERON':
        return 'Despite their large size, Great Blue Herons weigh only 5-8 pounds due to their hollow bones. They can hunt day and night thanks to specialized vision. During breeding season, they grow long plumes used in courtship displays.';
      default:
        return 'Further information about this bird is not available in our database at this time.';
    }
  }
}