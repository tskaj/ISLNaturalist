import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  // Base URL for DeepSeek API
  static String getBaseUrl() {
    // You may need to update this with the actual DeepSeek API URL
    return 'https://api.deepseek.com';
  }

  // Get treatment recommendations for a detected plant disease
  static Future<Map<String, dynamic>> getTreatmentRecommendation(String diseaseName, String cropType) async {
    try {
      // Construct a prompt for the DeepSeek API
      final prompt = "Provide a concise treatment recommendation for $diseaseName affecting $cropType plants. Include: \n"
          "1. Brief explanation of the disease\n"
          "2. Organic treatment options\n"
          "3. Chemical treatment options if necessary\n"
          "4. Prevention tips\n"
          "Keep the response informative but concise (150-200 words).";

      // You'll need to add your DeepSeek API key to the .env file
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '#';
      if (apiKey.isEmpty) {
        return {
          'success': false,
          'message': 'DeepSeek API key not found',
        };
      }

      // Make the API request to DeepSeek
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',  // Update with the appropriate model name
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Extract the treatment recommendation from the response
        final recommendation = jsonResponse['choices'][0]['message']['content'];
        return {
          'success': true,
          'recommendation': recommendation,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get treatment recommendation: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Error getting treatment recommendation: $error',
      };
    }
  }

  // Mock method for testing without actual API calls
  static Future<Map<String, dynamic>> getMockTreatmentRecommendation(String diseaseName, String cropType) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return a mock response based on the disease name with clear section markers
    String recommendation;
    
    if (diseaseName.toLowerCase().contains('healthy')) {
      recommendation = "Your $cropType plant appears healthy! Continue with regular care:\n\n"
          "Disease Information:\n"
          "Your plant is showing signs of good health with no visible disease symptoms.\n\n"
          "Treatment Recommendations:\n"
          "1. Water regularly but avoid overwatering\n"
          "2. Ensure adequate sunlight exposure\n"
          "3. Apply balanced fertilizer according to plant needs\n"
          "4. Monitor for early signs of pests or diseases\n\n"
          "Prevention Measures:\n"
          "1. Maintain good air circulation around plants\n"
          "2. Avoid wetting leaves when watering\n"
          "3. Remove any dead or decaying plant material promptly\n"
          "4. Inspect plants regularly for early detection of issues";
    } else if (diseaseName.toLowerCase().contains('blight')) {
      recommendation = "Treatment for $diseaseName on $cropType:\n\n"
          "Disease Information:\n"
          "Blight is a fungal disease that causes rapid browning and death of plant tissues. It typically appears as dark lesions on leaves that can quickly spread throughout the plant.\n\n"
          "Treatment Recommendations:\n"
          "Organic treatments:\n"
          "1. Remove and destroy infected plant parts immediately\n"
          "2. Apply copper-based fungicides or neem oil as directed\n"
          "3. Improve air circulation around plants\n\n"
          "Chemical options:\n"
          "1. Apply chlorothalonil or mancozeb-based fungicides\n"
          "2. Follow label instructions carefully\n"
          "3. Rotate fungicide types to prevent resistance\n\n"
          "Prevention Measures:\n"
          "1. Use disease-resistant varieties when planting\n"
          "2. Rotate crops annually to break disease cycles\n"
          "3. Avoid overhead watering to keep foliage dry\n"
          "4. Space plants properly for good air circulation";
    } else {
      recommendation = "Treatment for $diseaseName on $cropType:\n\n"
          "Disease Information:\n"
          "This condition affects plant health by damaging leaves and potentially reducing yield. Early detection and treatment are essential for managing this disease effectively.\n\n"
          "Treatment Recommendations:\n"
          "Organic treatments:\n"
          "1. Remove infected plant parts immediately\n"
          "2. Apply organic fungicides like neem oil or copper soap\n"
          "3. Introduce beneficial insects if appropriate\n\n"
          "Chemical options:\n"
          "1. Targeted fungicides or pesticides may be necessary for severe cases\n"
          "2. Always follow product instructions and safety guidelines\n"
          "3. Apply treatments during appropriate weather conditions\n\n"
          "Prevention Measures:\n"
          "1. Maintain proper plant spacing for good airflow\n"
          "2. Water at the base of plants to keep foliage dry\n"
          "3. Practice crop rotation to prevent disease buildup\n"
          "4. Use disease-resistant varieties when available";
    }
    
    return {
      'success': true,
      'recommendation': recommendation,
    };
  }
}