import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class WebImagePicker {
  static Future<Map<String, dynamic>?> pickImage() async {
    if (kIsWeb) {
      // For web platform
      try {
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
        
        if (pickedFile == null) return null;
        
        final bytes = await pickedFile.readAsBytes();
        return {
          'bytes': bytes,
          'name': pickedFile.name,
          'path': pickedFile.name, // Web doesn't have real paths
          'mimeType': 'image/jpeg', // Assuming JPEG, adjust as needed
        };
      } catch (e) {
        print('Error picking image on web: $e');
        return null;
      }
    } else {
      // For mobile platforms
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return null;
      
      final bytes = await pickedFile.readAsBytes();
      return {
        'bytes': bytes,
        'name': pickedFile.name,
        'path': pickedFile.path,
        'mimeType': 'image/jpeg', // Assuming JPEG, adjust as needed
      };
    }
  }
}