import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': responseData['token'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to login',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
        };
      } else {
        String errorMessage = 'Registration failed';
        
        if (responseData is Map) {
          if (responseData.containsKey('username')) {
            errorMessage = responseData['username'][0];
          } else if (responseData.containsKey('email')) {
            errorMessage = responseData['email'][0];
          } else if (responseData.containsKey('password')) {
            errorMessage = responseData['password'][0];
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'];
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }
}