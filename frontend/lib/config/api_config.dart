class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:8000/api';
  
  // JWT token key for storage
  static const String tokenKey = 'jwt_token';
  
  // Timeout duration for API requests
  static const Duration timeout = Duration(seconds: 30);
}