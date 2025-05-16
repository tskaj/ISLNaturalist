import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart'; // Make sure this import is present
import '../providers/auth_provider.dart';
import '../services/community_service.dart';
import '../utils/web_image_picker.dart';
import '../utils/constants.dart';
import '../widgets/create_post_widget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'new_login_screen.dart';
import 'package:flutter/foundation.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _posts = [];
  List<dynamic> _filteredPosts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Helper method to ensure image URLs are complete
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null) return '';
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else {
      // For relative URLs, construct the full URL
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      return '$baseUrl$imageUrl';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    _performSearch(_searchController.text);
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = _posts;
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await CommunityService.searchPosts(query, authProvider.token);
      
      if (mounted) {
        setState(() {
          _filteredPosts = results;
          _isSearching = false;
        });
      }
    } catch (error) {
      print('Error searching posts: $error');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    // Ensure context is still valid before navigating
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => const NewLoginScreen()), // Now this should be found
      );
    }
  }

  // In your _fetchPosts method, update it to use the static method:
  Future<void> _fetchPosts() async {
    print('[DEBUG] _fetchPosts: Starting fetch...'); // DEBUG
    setState(() {
      _isLoading = true;
    });
  
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('[DEBUG] _fetchPosts: Fetching posts with token: ${authProvider.token}'); // DEBUG
      final posts = await CommunityService.getPosts(authProvider.token);
      
      // Debug print to check what's coming back from the API
      print('[DEBUG] _fetchPosts: Fetched posts raw data: $posts'); // DEBUG
      
      // Debug print to check user data structure in each post
      // for (var post in posts) {
      //   print('Post user data: ${post['user']}');
      //   if (post['user'] is Map) {
      //     print('User profile image: ${post['user']['profile_image']}');
      //   }
      // }
      
      if (mounted) { // Check if the widget is still mounted
        print('[DEBUG] _fetchPosts: Widget is mounted. Updating state.'); // DEBUG
        setState(() {
          _posts = posts;
          _filteredPosts = posts;
          _isLoading = false;
        });
        print('[DEBUG] _fetchPosts: State updated successfully.'); // DEBUG
      } else {
        print('[DEBUG] _fetchPosts: Widget is NOT mounted. Skipping setState.'); // DEBUG
      }
    } catch (error) {
      print('[DEBUG] _fetchPosts: Error fetching posts: $error'); // DEBUG
      if (mounted) { // Check if mounted before setting state in catch block
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // And update your _loadPosts method to match:
  Future<void> _loadPosts() async {
    print('[DEBUG] _loadPosts: Starting load...'); // DEBUG
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('[DEBUG] _loadPosts: Loading posts with token: ${authProvider.token}'); // DEBUG
      final posts = await CommunityService.getPosts(authProvider.token);
      print('[DEBUG] _loadPosts: Loaded posts raw data: $posts'); // DEBUG
      
      if (mounted) { // Check if mounted
        print('[DEBUG] _loadPosts: Widget is mounted. Updating state.'); // DEBUG
        setState(() {
          _posts = posts;
          _filteredPosts = posts;
          // If there's an active search, filter the posts
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        });
        print('[DEBUG] _loadPosts: State updated successfully.'); // DEBUG
      } else {
        print('[DEBUG] _loadPosts: Widget is NOT mounted. Skipping setState.'); // DEBUG
      }
    } catch (error) {
      print('[DEBUG] _loadPosts: Error loading posts: $error'); // DEBUG
    }
  }

  // Replace the existing _createPost method with this fixed version
  void _createPost() {
    print('[DEBUG] _createPost: Showing modal bottom sheet.'); // DEBUG
    // Show bottom sheet with create post form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CreatePostWidget(
          onPostCreated: (caption, image) => _handlePostCreation(caption, image, null),
        ),
      ),
    );
  }

  // Add this new method to handle post creation
  Future<void> _handlePostCreation(String caption, dynamic image, dynamic response) async {
    print('[DEBUG] _handlePostCreation: Starting post creation...'); // DEBUG
    try {
      if (!mounted) {
        print('[DEBUG] _handlePostCreation: Widget not mounted at start. Aborting.'); // DEBUG
        return;
      }
      setState(() {
        _isLoading = true;
      });
      print('[DEBUG] _handlePostCreation: Set loading state to true.'); // DEBUG
  
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        print('[DEBUG] _handlePostCreation: Auth token is null. Showing error.'); // DEBUG
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      print('[DEBUG] _handlePostCreation: Auth token retrieved.'); // DEBUG

      // Call the service method
      Map<String, dynamic> result;
      print('[DEBUG] _handlePostCreation: Preparing to call CommunityService.createPost...'); // DEBUG
      if (kIsWeb && image is XFile) {
        print('[DEBUG] _handlePostCreation: Handling web image.'); // DEBUG
        final bytes = await image.readAsBytes();
        result = await CommunityService.createPost(caption, null, token, imageBytes: bytes);
      } else if (!kIsWeb && image is File) {
        print('[DEBUG] _handlePostCreation: Handling mobile image.'); // DEBUG
        result = await CommunityService.createPost(caption, image, token);
      } else if (image == null) {
        print('[DEBUG] _handlePostCreation: Handling post without image.'); // DEBUG
        result = await CommunityService.createPost(caption, null, token);
      } else {
        print('[DEBUG] _handlePostCreation: Invalid image type. Showing error.'); // DEBUG
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image type.')),
        );
        if (mounted) { setState(() { _isLoading = false; }); }
        return;
      }
      print('[DEBUG] _handlePostCreation: CommunityService.createPost returned: $result'); // DEBUG

      if (!mounted) {
         print('[DEBUG] _handlePostCreation: Widget not mounted after API call. Aborting.'); // DEBUG
         return;
      }

      if (result['success']) {
        print('[DEBUG] _handlePostCreation: Post creation successful. Popping modal.'); // DEBUG
        Navigator.of(context).pop(); // Close the bottom sheet FIRST
        print('[DEBUG] _handlePostCreation: Modal popped. Showing success snackbar.'); // DEBUG
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
        print('[DEBUG] _handlePostCreation: Calling _fetchPosts to refresh.'); // DEBUG
        await _fetchPosts(); // Refresh the posts list AFTER closing the sheet
        print('[DEBUG] _handlePostCreation: _fetchPosts completed.'); // DEBUG
      } else {
        print('[DEBUG] _handlePostCreation: Post creation failed. Error: ${result['message']}'); // DEBUG
        // print('Error creating post: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${result['message']}')), // Show error from result
        );
        // This second snackbar seems redundant and potentially confusing
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to create post: ${response?.body ?? 'Unknown error'}')),
        // );
      }
    } catch (error, stackTrace) { // Catch stack trace too
      print('[DEBUG] _handlePostCreation: Caught error: $error'); // DEBUG
      print('[DEBUG] _handlePostCreation: Stack trace: $stackTrace'); // DEBUG
      // print('Error creating post: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $error')),
        );
      }
    } finally {
      print('[DEBUG] _handlePostCreation: Entering finally block.'); // DEBUG
      if (mounted) {
        print('[DEBUG] _handlePostCreation: Widget mounted in finally. Setting loading state to false.'); // DEBUG
        setState(() {
          _isLoading = false;
        });
      } else {
        print('[DEBUG] _handlePostCreation: Widget NOT mounted in finally.'); // DEBUG
      }
    }
  }
  
  

  // Add this method to delete a post
  Future<void> _deletePost(int postId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.delete(
        Uri.parse('$baseUrl/api/community/posts/$postId/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Delete post response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        setState(() {
          _posts.removeWhere((p) => p['id'] == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  // Add this new method to delete a comment
  Future<void> _deleteComment(int commentId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      // Assuming the endpoint structure for comment deletion
      final url = Uri.parse('$baseUrl/api/community/comments/$commentId/'); 
      
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Delete comment response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Optionally, you might want to refresh the specific post's comments
        // or just show a success message and let the user manually refresh.
        // For simplicity, just show a snackbar here.
        // You might need to pass the postId to refresh comments if needed.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
        // Close the comments sheet after deletion
        Navigator.of(context).pop(); 
        // Refresh posts to reflect comment count change
        _loadPosts(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting comment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: ${error.toString()}')),
      );
    }
  }

  // Add login prompt widget
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Login Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'You need to login to access the community features and connect with other plant enthusiasts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const NewLoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuth;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade800,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text(
              'Community',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: !isLoggedIn
          ? _buildLoginPrompt()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildSearchSection(),
                    Expanded(
                      child: _posts.isEmpty
                          ? _buildEmptyState()
                          : _buildPostsList(),
                    ),
                  ],
                ),
      floatingActionButton: isLoggedIn ? FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.edit),
        label: const Text('Ask Community'),
        backgroundColor: Colors.blue,
      ) : null,
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Community',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts or users...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nature_people, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No posts yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPost,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Share Your Plants'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: () async {
        // Show a snackbar to indicate refresh is happening
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Add haptic feedback
        HapticFeedback.mediumImpact();
        
        // Perform the refresh
        await _loadPosts();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feed updated!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: _filteredPosts.isEmpty && _searchController.text.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No results found for "${_searchController.text}"',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Search'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredPosts.length,
              itemBuilder: (ctx, index) {
                final post = _filteredPosts[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildPostCard(post),
                    ),
                  ),
                );
              },
            ),
    );
  }
  Widget _buildPostCard(dynamic post) {
    // Get the full image URL using helper method
    String imageUrl = '';
    if (post['image'] != null) {
      imageUrl = _getFullImageUrl(post['image'].toString());
    }
    
    // Extract username and profile image from the post data
    String username = '';
    String? profileImageUrl;
    
    if (post['user'] != null) {
      if (post['user'] is Map) {
        // If user is a Map, extract username and profile_image
        username = post['user']['username'] ?? 'Unknown User';
        if (post['user']['profile_image'] != null) {
          // Use helper method to ensure URL is complete
          profileImageUrl = _getFullImageUrl(post['user']['profile_image'].toString());
          print('Profile image URL: $profileImageUrl'); // Debug print
        }
      } else if (post['user'] is String) {
        // If user is just a string (username), use that
        username = post['user'];
        // Try to get profile image from AuthProvider if this is the current user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.username == username && authProvider.profileImage != null) {
          // Use helper method to ensure URL is complete
          profileImageUrl = _getFullImageUrl(authProvider.profileImage);
          print('Profile image from auth provider: $profileImageUrl'); // Debug print
        }
      } else {
        username = 'Unknown User';
      }
    } else {
      username = 'Unknown User';
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUserPost = authProvider.username == username;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and post header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User avatar with animation
                Hero(
                  tag: 'avatar-${post['id']}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.green.shade100,
                    // Display profile image if available
                    child: profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CachedNetworkImage(
                            imageUrl: profileImageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) {
                              print('Error loading profile image: $error for URL: $profileImageUrl');
                              return Text(username.isNotEmpty ? username[0].toUpperCase() : '?', 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        )
                      : Text(username.isNotEmpty ? username[0].toUpperCase() : '?', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                // Username and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (post['created_at'] != null)
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateTime.tryParse(post['created_at'].toString()) != null
                                ? DateTime.parse(post['created_at'].toString()).toString().substring(0, 16)
                                : post['created_at'].toString(),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // More options button
                isCurrentUserPost
                  ? IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Delete Post'),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Post'),
                                      content: const Text('Are you sure you want to delete this post?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deletePost(post['id']);
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.edit, color: Colors.blue),
                                title: const Text('Edit Post'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  // Implement edit functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Edit functionality coming soon!')),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.share, color: Colors.blue),
                                title: const Text('Share'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  // Implement share functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Share functionality coming soon!')),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.report, color: Colors.orange),
                                title: const Text('Report'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  // Implement report functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Report functionality coming soon!')),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
          
          // Post caption
          if (post['caption'] != null && post['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post['caption'].toString(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          
          // Post image with animation
          if (imageUrl.isNotEmpty)
            Hero(
              tag: 'post-image-${post['id']}',
              child: Container(
                height: 300,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) {
                    print('Error loading image: $error');
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Image not available', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Post actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                        color: post['is_liked'] == true ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _likePost(post['id']),
                    ),
                    Text(
                      '${post['like_count'] ?? 0}',
                      style: TextStyle(
                        color: post['is_liked'] == true ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                // Comments button
                GestureDetector(
                  onTap: () => _showComments(post),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${post['comment_count'] ?? 0}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                // React button (emoji)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.emoji_emotions),
                  onSelected: (String reaction) {
                    _reactToPost(post['id'], reaction);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'like',
                      child: Row(
                        children: [
                          Text('👍 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Like'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'love',
                      child: Row(
                        children: [
                          Text('❤️ ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Love'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'laugh',
                      child: Row(
                        children: [
                          Text('😂 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Laugh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'wow',
                      child: Row(
                        children: [
                          Text('😮 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Wow'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'sad',
                      child: Row(
                        children: [
                          Text('😢 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Sad'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'angry',
                      child: Row(
                        children: [
                          Text('😡 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Angry'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Display comment count if there are comments
          if ((post['comments'] as List?)?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: GestureDetector(
                onTap: () => _showComments(post),
                child: Text(
                  'View all ${(post['comments'] as List).length} comments',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }
  // Add this method to create a comment on a post
  Future<void> _createComment(int postId, String content) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/posts/$postId/comments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      print('Create comment response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully')),
        );
        // Refresh posts to show updated comment count
        _loadPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error creating comment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  // Add this method to create a reply to a comment
  Future<void> _createReply(int commentId, String content) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/comments/$commentId/reply/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      print('Create reply response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added successfully')),
        );
        // Refresh posts to show updated comment/reply
        _loadPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reply: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error creating reply: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  // Add this method to like/unlike a comment
  Future<void> _likeComment(int commentId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like comments')),
      );
      return;
    }

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    try {
      final result = await CommunityService.likeComment(commentId, token);
      if (result['success']) {
        // Refresh posts to show updated like count
        _fetchPosts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }


  // Add this method to handle liking a reply
  Future<void> _likeReply(int replyId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuth) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to like replies')),
        );
        return;
      }

      final token = authProvider.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
        return;
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/replies/$replyId/like/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Like reply response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh posts to update like status
        _fetchPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like reply: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error liking reply: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }
  // Add this method to like/unlike a post
  Future<void> _likePost(int postId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/posts/$postId/like/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Like post response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update the UI to reflect the like/unlike
        setState(() {
          final postIndex = _posts.indexWhere((p) => p['id'] == postId);
          if (postIndex != -1) {
            final post = _posts[postIndex];
            final isLiked = post['is_liked'] == true;
            
            // Toggle like status
            post['is_liked'] = !isLiked;
            
            // Update like count
            if (isLiked) {
              post['like_count'] = (post['like_count'] ?? 1) - 1;
            } else {
              post['like_count'] = (post['like_count'] ?? 0) + 1;
            }
            
            _posts[postIndex] = post;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error liking post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }
  void _showComments(Map<String, dynamic> post) {
    final TextEditingController commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments (${post['comment_count'] ?? 0})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            
            // Comments list
            Expanded(
              child: post['comments'] != null && (post['comments'] as List).isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: (post['comments'] as List).length,
                    itemBuilder: (context, index) {
                      final comment = (post['comments'] as List)[index];
                      return _buildCommentItem(comment, post['id']);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            
            // Comment input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      if (commentController.text.trim().isNotEmpty) {
                        _createComment(post['id'], commentController.text.trim());
                        commentController.clear();
                        Navigator.of(ctx).pop(); // Close the sheet after commenting
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Add this method to build a comment item
  Widget _buildCommentItem(Map<String, dynamic> comment, int postId) {
    final TextEditingController replyController = TextEditingController();
    final bool hasReplies = comment['replies'] != null && (comment['replies'] as List).isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  comment['user']['username']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment content
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['user']['username'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(comment['content'] ?? ''),
                        ],
                      ),
                    ),
                    
                    // Comment actions
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Row(
                        children: [
                          // Like button
                          TextButton.icon(
                            icon: Icon(
                              comment['is_liked'] == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: comment['is_liked'] == true
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            label: Text(
                              '${comment['likes_count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: comment['is_liked'] == true
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            onPressed: () => _likeComment(comment['id']),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Reply button
                          GestureDetector(
                            onTap: () {
                              // Show reply input
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Reply to comment',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: replyController,
                                          decoration: const InputDecoration(
                                            hintText: 'Write your reply...',
                                            border: OutlineInputBorder(),
                                          ),
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (replyController.text.trim().isNotEmpty) {
                                              _createReply(
                                                comment['id'],
                                                replyController.text.trim(),
                                              );
                                              Navigator.of(ctx).pop();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Post Reply'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Delete button (only for user's own comments)
                          if (comment['user']['id'] == Provider.of<AuthProvider>(context, listen: false).username)
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: GestureDetector(
                                onTap: () => _deleteComment(comment['id']),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Replies
        if (hasReplies)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: [
                for (var reply in comment['replies'])
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            reply['user']['username']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reply['user']['username'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reply['content'] ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Reply actions
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Row(
                                  children: [
                                    // Like button for reply
                                    IconButton(
                                      icon: Icon(
                                        reply['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                                        color: reply['is_liked'] == true ? Colors.red : Colors.grey,
                                        size: 16,
                                      ),
                                      onPressed: () => _likeReply(reply['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      iconSize: 16,
                                    ),
                                    Text(
                                      '${reply['like_count'] ?? 0}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    
                                    // Delete button for reply (only for user's own replies)
                                    if (reply['user']['id'] == Provider.of<AuthProvider>(context, listen: false).username)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12),
                                        child: GestureDetector(
                                          onTap: () => _deleteComment(reply['id']),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 12,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Show reply dialog
  void _showReplyDialog(int postId, int commentId) {
    final replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to comment'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.isEmpty) return;
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;
              if (token == null) return;
              
              try {
                final result = await CommunityService.addComment(
                  postId,
                  replyController.text,
                  token,
                  parentId: commentId,
                );
                
                if (result['success']) {
                  Navigator.of(ctx).pop();
                  await _fetchPosts();
                  Navigator.of(context).pop(); // Close the comments sheet
                  _showComments(_posts.firstWhere((p) => p['id'] == postId)); // Reopen with updated data
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${error.toString()}')),
                );
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  // Format date for comments
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString.toString();
    }
  }
  
  // Add this helper method for filter chips
  // Removed _buildFilterChip method as it's been replaced by search functionality
  /*
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
  */

  
// Implement the _reactToPost method
Future<void> _reactToPost(int postId, String reaction) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;
    
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final url = Uri.parse('$baseUrl/api/community/posts/$postId/react/');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reaction_type': reaction,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      await _fetchPosts(); // Refresh posts to update reactions
      HapticFeedback.lightImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to react to post: ${response.body}')),
      );
    }
  } catch (error) {
    print('Error reacting to post: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.toString()}')),
    );
  }
}}