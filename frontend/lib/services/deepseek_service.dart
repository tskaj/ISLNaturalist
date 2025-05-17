import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepseekService {
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

  // Get response from DeepSeek AI
  Future<String> getResponse(String prompt) async {
    try {
      // In a production app, this would call your actual API
      // For now, we'll use intelligent responses based on the prompt content
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (prompt.toLowerCase().contains('insect')) {
        return _getInsectResponse(prompt);
      } else if (prompt.toLowerCase().contains('bird')) {
        return _getBirdResponse(prompt);
      } else {
        return _getPlantResponse(prompt);
      }
    } catch (e) {
      throw Exception('Error getting AI response: $e');
    }
  }
  
  // Helper method to generate insect responses
  String _getInsectResponse(String prompt) {
    final promptLower = prompt.toLowerCase();
    if (promptLower.contains('scientific name')) {
      return "The scientific classification of this insect includes its genus and species, which places it within the broader taxonomic hierarchy. This classification helps scientists understand evolutionary relationships between different insects. The scientific naming follows the binomial nomenclature system established by Carl Linnaeus.";
    } else if (promptLower.contains('harmful') || promptLower.contains('beneficial')) {
      return "This insect plays a specific role in the ecosystem that can be considered either beneficial or harmful depending on context. Many insects serve as pollinators, decomposers, or natural pest control. Others may damage crops or spread diseases. It's important to understand their full ecological role before classifying them simply as 'good' or 'bad'.";
    } else if (promptLower.contains('eat') || promptLower.contains('diet')) {
      return "This insect's diet consists of specific foods depending on its life stage. Many insects have completely different diets during their larval and adult stages. Common insect food sources include plant matter (leaves, nectar, fruits), other insects, blood (in the case of some parasitic species), or decaying organic material.";
    } else if (promptLower.contains('lifecycle') || promptLower.contains('life cycle')) {
      return "This insect goes through several distinct stages in its lifecycle. Most insects undergo either complete metamorphosis (egg, larva, pupa, adult) or incomplete metamorphosis (egg, nymph, adult). Each stage serves a different biological purpose, from growth and development to reproduction and dispersal.";
    } else if (promptLower.contains('found') || promptLower.contains('habitat')) {
      return "This insect can be found in specific habitats that provide the conditions it needs to survive. These include particular temperature ranges, humidity levels, food sources, and protection from predators. Many insects are highly adaptable but may still be limited to certain geographic regions or ecosystems.";
    } else {
      return "This insect has specific characteristics that make it unique in the insect world. It has evolved specialized traits for survival in its particular ecological niche. Understanding its behavior, physical characteristics, and life history can help with identification and management if needed.";
    }
  }
  
  // Helper method to generate bird responses
  String _getBirdResponse(String prompt) {
    final promptLower = prompt.toLowerCase();
    if (promptLower.contains('scientific name')) {
      return "The scientific name of this bird follows the binomial nomenclature system, placing it within a specific genus and species. This classification helps ornithologists trace evolutionary relationships between different bird groups and establish proper taxonomic placement within the class Aves.";
    } else if (promptLower.contains('found') || promptLower.contains('habitat')) {
      return "This bird species inhabits specific ecological regions that provide its essential needs: food sources, nesting sites, and protection. Some birds are habitat specialists, requiring very particular environments, while others are generalists that can adapt to various settings, including urban areas. The range may change seasonally for migratory species.";
    } else if (promptLower.contains('eat') || promptLower.contains('diet')) {
      return "This bird's diet consists of particular foods that reflect its evolutionary adaptations and ecological niche. The diet may include seeds, berries, insects, small vertebrates, or nectar, depending on the species. Many birds have specialized beaks that are adapted for their particular feeding habits.";
    } else if (promptLower.contains('migratory')) {
      return "This bird species follows specific migration patterns influenced by seasonal food availability and breeding requirements. Not all birds migrate; some are year-round residents in their territories. Migratory birds may travel thousands of miles between breeding and wintering grounds, following established flyways and using celestial, magnetic, and geographic cues for navigation.";
    } else if (promptLower.contains('sound') || promptLower.contains('call')) {
      return "This bird produces distinctive calls and songs that serve various purposes, including territorial defense, mate attraction, and communication with offspring or flock members. Each species has characteristic vocalizations that bird enthusiasts use for identification. Some birds are also known for their ability to mimic other sounds in their environment.";
    } else {
      return "This bird species has unique characteristics that distinguish it from other avian species. Birds are warm-blooded vertebrates characterized by feathers, toothless beaked jaws, a high metabolic rate, a four-chambered heart, and lightweight but strong skeletons. This particular species has evolved specialized traits for its ecological niche.";
    }
  }
  
  // Helper method to generate plant/disease responses
  String _getPlantResponse(String prompt) {
    if (prompt.toLowerCase().contains('treatment')) {
      return "Treatment for this plant disease should follow an integrated approach:\n\n"
          "1. Cultural controls: Remove and destroy infected plant material to reduce disease spread\n"
          "2. Adjust watering practices to avoid wetting foliage and creating favorable disease conditions\n"
          "3. Ensure proper spacing between plants for adequate air circulation\n"
          "4. Apply organic fungicides like neem oil or copper-based products for mild infections\n"
          "5. For severe infections, consider conventional fungicides appropriate for the specific pathogen\n"
          "6. Always follow label directions when applying any treatment products\n\n"
          "Prevention is key for long-term management. Practice crop rotation, use resistant varieties when available, and maintain good garden sanitation.";
    } else {
      return "This plant condition has specific characteristics that help with proper identification and management. Understanding the causal agent (whether fungal, bacterial, viral, or environmental) is crucial for effective treatment. Regular monitoring of plant health and early intervention can prevent severe crop damage and yield loss.";
    }
  }
}