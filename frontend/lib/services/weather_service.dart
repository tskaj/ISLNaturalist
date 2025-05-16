import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static String getBaseUrl() {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    } catch (e) {
      print("Error accessing environment variables: $e");
      return 'http://localhost:8000';
    }
  }
  
  static final String baseUrl = getBaseUrl();

  /// Get current user location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      throw Exception('Location permissions are permanently denied');
    } 

    // When we reach here, permissions are granted and we can get the location
    return await Geolocator.getCurrentPosition();
  }

  /// Get current weather data for a location
  static Future<Map<String, dynamic>> getCurrentWeather(double latitude, double longitude, {String units = 'metric'}) async {
    try {
      final url = Uri.parse('$baseUrl/api/weather/current/')
          .replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'units': units,
      });

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch current weather');
      }
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  /// Get 5-day weather forecast for a location
  static Future<Map<String, dynamic>> getWeatherForecast(double latitude, double longitude, {String units = 'metric'}) async {
    try {
      final url = Uri.parse('$baseUrl/api/weather/forecast/')
          .replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'units': units,
      });

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch weather forecast');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }

  /// Get spray recommendations based on weather forecast
  static Future<Map<String, dynamic>> getSprayRecommendations(double latitude, double longitude, {String units = 'metric'}) async {
    try {
      final url = Uri.parse('$baseUrl/api/weather/spray-recommendations/')
          .replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'units': units,
      });

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch spray recommendations');
      }
    } catch (e) {
      throw Exception('Error fetching spray recommendations: $e');
    }
  }

  /// Get weather icon URL from OpenWeather
  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Convert temperature based on unit
  static String formatTemperature(double temp, String units) {
    String symbol = units == 'imperial' ? '°F' : '°C';
    return '${temp.round()}$symbol';
  }

  /// Format timestamp to readable date/time
  static String formatDateTime(int timestamp, {bool dateOnly = false}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    if (dateOnly) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get wind direction as text (N, NE, E, etc.)
  static String getWindDirection(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}