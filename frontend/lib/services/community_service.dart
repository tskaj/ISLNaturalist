import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommunityService {
  static String getBaseUrl() {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }
  
  // Search posts by query string
  static Future<List<dynamic>> searchPosts(String query, String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Get all posts first
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/api/community/posts/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final allPosts = json.decode(response.body);
        
        // If query is empty, return all posts
        if (query.isEmpty) {
          return allPosts;
        }
        
        // Filter posts client-side based on caption content
        final lowercaseQuery = query.toLowerCase();
        return allPosts.where((post) {
          final caption = post['caption']?.toString().toLowerCase() ?? '';
          final username = post['user']?['username']?.toString().toLowerCase() ?? '';
          return caption.contains(lowercaseQuery) || username.contains(lowercaseQuery);
        }).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Network error: ${error.toString()}');
    }
  }

  static Future<List<dynamic>> getPosts(String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${getBaseUrl()}/api/community/posts/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Network error: ${error.toString()}');
    }
  }

  static Future<Map<String, dynamic>> likePost(int postId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/posts/$postId/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'is_liked': responseData['is_liked'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to like post',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> addComment(
      int postId, String content, String token, {int? parentId}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'content': content,
      };
      
      if (parentId != null) {
        requestBody['parent_id'] = parentId;
      }
      
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/posts/$postId/comments/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'comment': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to add comment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> createPost(
      String caption, File? image, String token, {Uint8List? imageBytes}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${getBaseUrl()}/api/community/posts/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['caption'] = caption;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      } else if (imageBytes != null) {
        // For web platform
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'web_image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to create post',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> reactToPost(
      int postId, String reactionType, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/posts/$postId/react/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reaction_type': reactionType,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'reaction': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to react to post',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }
  
  // Add these static methods to your CommunityService class
  
  // Get comments for a post
  static Future<List<dynamic>> getComments(int postId, String? token) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/posts/$postId/comments/'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error fetching comments: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (error) {
      print('Error fetching comments: $error');
      return [];
    }
  }
  
  // Create a comment
  static Future<Map<String, dynamic>> createComment(
    int postId,
    String content,
    String token,
  ) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/posts/$postId/comments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'comment': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create comment: ${response.statusCode}',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Error: $error',
      };
    }
  }
  
  // Create a reply
  static Future<Map<String, dynamic>> createReply(
    int commentId,
    String content,
    String token,
  ) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/comments/$commentId/reply/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'reply': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create reply: ${response.statusCode}',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Error: $error',
      };
    }
  }

  static Future<Map<String, dynamic>> likeComment(int commentId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/comments/$commentId/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to like comment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> likeReply(int replyId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/replies/$replyId/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'liked': response.statusCode == 201,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to like reply',
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