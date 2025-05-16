import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class CreatePostWidget extends StatefulWidget {
  final Function(String, dynamic) onPostCreated;
  
  const CreatePostWidget({super.key, required this.onPostCreated});
  
  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final _captionController = TextEditingController();
  dynamic _selectedImage;
  bool _isLoading = false;
  
  Future<void> _submitPost() async {
    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a caption')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuth) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to create a post')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      await widget.onPostCreated(_captionController.text, _selectedImage);
      
      // Clear the form
      _captionController.clear();
      setState(() {
        _selectedImage = null;
        _isLoading = false;
      });
      
      // Close the bottom sheet
      Navigator.of(context).pop();
    } catch (error) {
      print('Error creating post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedImage != null) {
        setState(() {
          if (kIsWeb) {
            // For web, store the XFile directly
            _selectedImage = pickedImage;
          } else {
            // For mobile platforms
            _selectedImage = File(pickedImage.path);
          }
        });
      }
    } catch (error) {
      print('Error picking image: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $error')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'Share something about your plants...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Add Image'),
              ),
              const SizedBox(width: 8),
              if (_selectedImage != null)
                Expanded(
                  child: Text(
                    'Image selected',
                    style: TextStyle(color: Colors.green),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}