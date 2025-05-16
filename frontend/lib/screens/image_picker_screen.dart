import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Widget _buildImageDisplay() {
    if (_selectedImage == null) {
      return const SizedBox();
    }

    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(snapshot.data!);
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    } else {
      return Image.file(File(_selectedImage!.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Picker')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Pick Image'),
          ),
          _buildImageDisplay(),
        ],
      ),
    );
  }
}