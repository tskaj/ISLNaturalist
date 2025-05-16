import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'new_login_screen.dart';
import 'new_register_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  // Helper method to ensure image URLs are complete
  

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BioScout Islamabad', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section with gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: !isLoggedIn ?
                _buildNotLoggedInView(context)
              :
                _buildLoggedInView(context, authProvider),
            ),           
            // Menu sections with subtle dividers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    child: Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  // Feature cards
                  _buildGrowTogetherSection(context),
                  const SizedBox(height: 12),
                  _buildFeedbackSection(context),
                  const SizedBox(height: 12),
                  _buildLanguageSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Stories section
                  _buildStoriesSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );}
    
      static _getFullImageUrl(String imageUrl) {
         if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else {
      // For relative URLs, construct the full URL
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      return '$baseUrl$imageUrl';
      }
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join BioScout Islamabad Community',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewLoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewRegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show profile image options
  void _showProfileImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.of(ctx).pop();
              _uploadProfileImage(context, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.of(ctx).pop();
              _uploadProfileImage(context, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // Method to upload profile image
  Future<void> _uploadProfileImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 600,
      );

      if (pickedImage == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading profile image...')),
      );

      // Prepare the request
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      // Corrected the endpoint based on backend URL configuration
      final url = Uri.parse('$baseUrl/profile/'); 
      
      // Changed method to PUT as profile update is likely idempotent
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add the image file
      if (kIsWeb) {
        final imageBytes = await pickedImage.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          imageBytes,
          filename: pickedImage.name, // Use pickedImage.name for web
          contentType: MediaType('image', 'jpeg'), // Adjust content type if needed
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          pickedImage.path,
          contentType: MediaType('image', 'jpeg'), // Adjust content type if needed
        ));
      }
      
      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        // Update the profile image in the provider
        final data = json.decode(responseData);
        if (data['profile_image'] != null) {
          authProvider.updateProfileImage(data['profile_image']);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: ${responseData}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  Widget _buildLoggedInView(BuildContext context, AuthProvider authProvider) {
  //   String _getFullImageUrl(String imageUrl) {
  //   if (imageUrl.startsWith('http')) {
  //     return imageUrl;
  //   } else {
  //     // For relative URLs, construct the full URL
  //     final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  //     return '$baseUrl$imageUrl';
  //   }
  // }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with avatar and user info
          Row(
            children: [
              GestureDetector(
                onTap: () => _showProfileImageOptions(context),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.green.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: authProvider.profileImage != null
                            ? CachedNetworkImage(
                                imageUrl: ProfileScreen._getFullImageUrl(authProvider.profileImage!),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green.shade300,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  print('Error loading profile image: $error');
                                  return Center(
                                    child: Text(
                                      authProvider.username?[0].toUpperCase() ?? 'U',
                                      style: TextStyle(fontSize: 42, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  authProvider.username?[0].toUpperCase() ?? 'U',
                                  style: TextStyle(fontSize: 42, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(authProvider.username != null && authProvider.username!.isNotEmpty)
                      Text(
                        authProvider.username!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Only show email if available
                    if (authProvider.email != null && authProvider.email!.isNotEmpty)
                      Text(
                        authProvider.email!,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Account options in a card with rounded corners
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Account settings option
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.settings, color: Colors.blue.shade700),
                  ),
                  title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                    );
                  },
                ),
                
                Divider(height: 1, thickness: 1, indent: 70, endIndent: 20, color: Colors.grey.shade200),
                
                // Sign out option
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.exit_to_app, color: Colors.red.shade700),
                  ),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    authProvider.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowTogetherSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.eco,
                color: Colors.green.shade700,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grow smart together!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text( 
                    'Share BioScout Islamabad and help people solve their observations problems.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Share app functionality
                try {
                  // This would typically use a share package like share_plus
                  // For now, we'll show a snackbar indicating sharing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing BioScout Islamabads with your friends!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sharing app: ${e.toString()}')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'Share BioScout Islamabad',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.star_border,
                color: Colors.amber.shade700,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How is your experience with BioScout Islamabad app?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We\'d love to hear your thoughts and suggestions.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Show feedback dialog
                _showFeedbackDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade50,
                foregroundColor: Colors.amber.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'Feedback',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.language,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Language Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(context, 'English', const Locale('en', '')),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            _buildLanguageOption(context, 'اردو (Urdu)', const Locale('ur', '')),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, Locale locale) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSelected = languageProvider.locale?.languageCode == locale.languageCode;
    
    return InkWell(
      onTap: () {
        languageProvider.setLocale(locale);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Row(
          children: [
            Text(
              language,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Method to show feedback dialog
  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We appreciate your feedback to improve BioScout Islamabad!'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Submit feedback
              if (feedbackController.text.isNotEmpty) {
                // In a real app, this would send the feedback to a backend
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // Method to show article details
  void _showArticleDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.eco, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BioScout Islamabad',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '2 days ago',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Article title
                const Text(
                  'Pest Control: Managing Sucking Pests',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Article image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/pests.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Article content
                const Text(
                  'Sucking pests are a common problem for many crops. These pests feed by piercing plant tissues and extracting sap, which can lead to stunted growth, yellowing, and even plant death if left unchecked.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Common sucking pests include:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Aphids - Small, soft-bodied insects that cluster on new growth'),
                _buildBulletPoint('Whiteflies - Tiny, white flying insects that feed on the undersides of leaves'),
                _buildBulletPoint('Spider mites - Microscopic pests that cause stippling on leaves'),
                _buildBulletPoint('Leafhoppers - Wedge-shaped insects that hop when disturbed'),
                const SizedBox(height: 12),
                const Text(
                  'Management strategies:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Regular monitoring of plants for early detection'),
                _buildBulletPoint('Introducing beneficial insects like ladybugs and lacewings'),
                _buildBulletPoint('Using insecticidal soaps for mild infestations'),
                _buildBulletPoint('Applying neem oil as a natural deterrent'),
                _buildBulletPoint('Maintaining plant health through proper watering and fertilization'),
                const SizedBox(height: 20),
                const Text(
                  'Remember that prevention is always better than cure. Keep your garden clean, remove affected leaves promptly, and maintain biodiversity to keep pest populations in check naturally.',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
                ),
                const SizedBox(height: 30),
                // Article footer
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('42 likes', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    Icon(Icons.comment_outlined, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('8 comments', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stories picked for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.asset(
                  'assets/images/pests.jpg',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.eco, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BioScout Islamabad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '2 days ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pest Control: Managing Sucking Pests',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn effective strategies to identify and manage sucking pests that can damage your crops.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('245 views', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            _showArticleDetails(context);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text('Read More', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                        ),
                      ],
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
}