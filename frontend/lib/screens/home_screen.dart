import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/disease_service.dart';
import '../services/insect_detection_service.dart';
import '../services/bird_detection_service.dart';
import '../services/weather_service.dart';
import 'new_login_screen.dart';
import 'community_screen.dart';
import 'disease_detail_screen.dart';
import 'insect_detail_screen.dart';
import 'bird_detail_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../screens/weather_details.dart';

// Enum to represent the type of detection
enum DetectionType { plant, insect, bird }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _detectionResult;
  String _selectedCrop = 'tomato';
  List<String> _availableCrops = ['tomato'];
  bool _loadingCrops = true;

  // Add detection type selection
  DetectionType _detectionType = DetectionType.plant;

  // Weather data
  bool _loadingWeather = true;
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _weatherForecast;
  Map<String, dynamic>? _sprayRecommendations;
  String _weatherUnits = 'metric';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _fetchAvailableCrops();
  }

  Future<void> _fetchAvailableCrops() async {
    try {
      // This would typically call an API to get available crops
      // For now, we'll use a static list
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _availableCrops = ['tomato', 'potato', 'corn', 'wheat', 'rice'];
        _loadingCrops = false;
      });
    } catch (e) {
      print('Error fetching crops: $e');
      setState(() {
        _loadingCrops = false;
      });
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _loadingWeather = true;
    });

    try {
      // Get current location
      final position = await WeatherService.getCurrentLocation();

      // Fetch weather data in parallel
      final weatherFutures = await Future.wait([
        WeatherService.getCurrentWeather(position.latitude, position.longitude,
            units: _weatherUnits),
        WeatherService.getWeatherForecast(position.latitude, position.longitude,
            units: _weatherUnits),
        WeatherService.getSprayRecommendations(
            position.latitude, position.longitude,
            units: _weatherUnits),
      ]);

      if (mounted) {
        setState(() {
          _currentWeather = weatherFutures[0];
          _weatherForecast = weatherFutures[1];
          _sprayRecommendations = weatherFutures[2];
          _loadingWeather = false;
        });
      }
    } catch (e) {
      print('Error loading weather data: $e');
      if (mounted) {
        setState(() {
          _loadingWeather = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not load weather data: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToLogin() {
    // Ensure context is still valid before navigating
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (ctx) =>
                const NewLoginScreen()), // Now this should be found
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // If we're detecting plants, use the leaf validation
      if (_detectionType == DetectionType.plant) {
        final isValidLeafImage = await _validateLeafImage(image);
        if (isValidLeafImage) {
          setState(() {
            _selectedImage = image;
            _detectionResult = null;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      AppLocalizations.of(context)?.pleaseSelectLeafImage ??
                          'Please select a leaf image')),
            );
          }
        }
      } else {
        // For insects and birds, just validate the file format
        final isValidImage = await _validateImageBasic(image);
        if (isValidImage) {
          setState(() {
            _selectedImage = image;
            _detectionResult = null;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Please select a valid image file (JPG, JPEG, or PNG)')),
            );
          }
        }
      }
    }
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // If we're detecting plants, use the leaf validation
      if (_detectionType == DetectionType.plant) {
        final isValidLeafImage = await _validateLeafImage(image);
        if (isValidLeafImage) {
          setState(() {
            _selectedImage = image;
            _detectionResult = null;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      AppLocalizations.of(context)?.pleaseSelectLeafImage ??
                          'Please select a leaf image')),
            );
          }
        }
      } else {
        // For insects and birds, just validate the file format
        final isValidImage = await _validateImageBasic(image);
        if (isValidImage) {
          setState(() {
            _selectedImage = image;
            _detectionResult = null;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Please select a valid image file (JPG, JPEG, or PNG)')),
            );
          }
        }
      }
    }
  }

  // Basic image validation for insect and bird images
  Future<bool> _validateImageBasic(XFile image) async {
    // Basic validation based on file extension
    final validExtensions = ['jpg', 'jpeg', 'png'];

    // Handle both regular file paths and blob URLs
    String fileExtension;
    if (kIsWeb && image.path.startsWith('blob:')) {
      // For web, we can't rely on the path for extension
      // Instead, check the name property or use a default
      final fileName = image.name?.toLowerCase() ?? '';
      fileExtension = fileName.contains('.')
          ? fileName.split('.').last
          : 'jpg'; // Default to jpg if no extension found
      print('Web image detected, using name for extension: $fileExtension');
    } else {
      // For mobile platforms, use the path
      fileExtension = image.path.split('.').last.toLowerCase();
    }

    if (!validExtensions.contains(fileExtension)) {
      print('Invalid file extension: $fileExtension');
      return false;
    }

    // Size validation
    try {
      final fileBytes = await image.readAsBytes();
      final fileSizeInMB = fileBytes.length / (1024 * 1024);
      if (fileSizeInMB > 10) {
        // Limit to 10MB
        print('File too large: ${fileSizeInMB.toStringAsFixed(2)} MB');
        return false;
      }
    } catch (e) {
      print('Error checking file size: $e');
      // Continue with validation if size check fails
    }

    return true;
  }

  Future<bool> _validateLeafImage(XFile image) async {
    // Basic validation based on file extension
    final validExtensions = ['jpg', 'jpeg', 'png'];

    // Handle both regular file paths and blob URLs
    String fileExtension;
    if (kIsWeb && image.path.startsWith('blob:')) {
      // For web, we can't rely on the path for extension
      // Instead, check the name property or use a default
      final fileName = image.name?.toLowerCase() ?? '';
      fileExtension = fileName.contains('.')
          ? fileName.split('.').last
          : 'jpg'; // Default to jpg if no extension found
      print('Web image detected, using name for extension: $fileExtension');
    } else {
      // For mobile platforms, use the path
      fileExtension = image.path.split('.').last.toLowerCase();
    }

    if (!validExtensions.contains(fileExtension)) {
      print('Invalid file extension: $fileExtension');
      return false;
    }

    // Size validation
    try {
      final fileBytes = await image.readAsBytes();
      final fileSizeInMB = fileBytes.length / (1024 * 1024);
      if (fileSizeInMB > 10) {
        // Limit to 10MB
        print('File too large: ${fileSizeInMB.toStringAsFixed(2)} MB');
        return false;
      }
    } catch (e) {
      print('Error checking file size: $e');
      // Continue with validation if size check fails
    }

    // Use the same validation approach for both web and mobile
    try {
      final result = await DiseaseService.validateLeafImage(image);

      if (result['success']) {
        // Check if it's a leaf with sufficient confidence
        final isLeaf = result['isLeaf'] as bool;
        final confidence = result['confidence'] as double;

        // Set a reasonable confidence threshold
        final confidenceThreshold = 0.6; // 60% confidence threshold

        print('Leaf validation result: isLeaf=$isLeaf, confidence=$confidence');
        return isLeaf && confidence >= confidenceThreshold;
      } else {
        // If API call failed, show the error but don't accept the image
        print('Leaf validation API error: ${result['message']}');
        // Don't default to accepting non-leaf images
        return false;
      }
    } catch (e) {
      // If there's an exception, don't accept the image
      print('Error during leaf validation: $e');
      return false;
    }
  }

  Future<void> _detectObject() async {
    final localizations = AppLocalizations.of(context);
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                localizations?.pleaseSelectImage ?? 'Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // Handle different detection types
      switch (_detectionType) {
        case DetectionType.plant:
          result = await _detectPlantDisease();
          break;
        case DetectionType.insect:
          result = await _detectInsect();
          break;
        case DetectionType.bird:
          result = await _detectBird();
          break;
        default:
          throw Exception('Unknown detection type');
      }

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _detectionResult = result['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Method for plant disease detection
  Future<Map<String, dynamic>> _detectPlantDisease() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (kIsWeb) {
      // For web, we need to handle this differently
      final bytes = await _selectedImage!.readAsBytes();
      return token != null
          ? await DiseaseService.detectDiseaseWeb(bytes, token,
              cropType: _selectedCrop)
          : await DiseaseService.detectDiseaseAnonymousWeb(bytes,
              cropType: _selectedCrop);
    } else {
      // For mobile platforms
      final file = File(_selectedImage!.path);
      return token != null
          ? await DiseaseService.detectDisease(file, token,
              cropType: _selectedCrop)
          : await DiseaseService.detectDiseaseAnonymousMobile(file,
              cropType: _selectedCrop);
    }
  }

  // Method for insect detection
  Future<Map<String, dynamic>> _detectInsect() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      if (kIsWeb) {
        // For web platforms
        final bytes = await _selectedImage!.readAsBytes();
        Map<String, dynamic> result;

        if (token != null) {
          result =
              await InsectDetectionService.detectInsectSpeciesWeb(bytes, token);
        } else {
          result = await InsectDetectionService.detectInsectSpeciesAnonymousWeb(
              bytes);
        }

        // Log the result for debugging
        print("Insect detection raw result: $result");

        return {'success': true, 'data': result};
      } else {
        // For mobile platforms
        final file = File(_selectedImage!.path);
        Map<String, dynamic> result;

        if (token != null) {
          result =
              await InsectDetectionService.detectInsectSpecies(file, token);
        } else {
          result =
              await InsectDetectionService.detectInsectSpeciesAnonymous(file);
        }

        // Log the result for debugging
        print("Insect detection raw result: $result");

        return {'success': true, 'data': result};
      }
    } catch (e) {
      print("Error in _detectInsect: $e");
      return {'success': false, 'message': 'Error detecting insect: $e'};
    }
  }

  // Method for bird detection
  Future<Map<String, dynamic>> _detectBird() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      if (kIsWeb) {
        // For web platforms
        final bytes = await _selectedImage!.readAsBytes();
        Map<String, dynamic> result;

        if (token != null) {
          result =
              await BirdDetectionService.detectBirdSpeciesWeb(bytes, token);
        } else {
          result =
              await BirdDetectionService.detectBirdSpeciesAnonymousWeb(bytes);
        }

        // Log the result for debugging
        print("Bird detection raw result: $result");

        return {'success': true, 'data': result};
      } else {
        // For mobile platforms
        final file = File(_selectedImage!.path);
        Map<String, dynamic> result;

        if (token != null) {
          result = await BirdDetectionService.detectBirdSpecies(file, token);
        } else {
          result = await BirdDetectionService.detectBirdSpeciesAnonymous(file);
        }

        // Log the result for debugging
        print("Bird detection raw result: $result");

        return {'success': true, 'data': result};
      }
    } catch (e) {
      print("Error in _detectBird: $e");
      return {'success': false, 'message': 'Error detecting bird: $e'};
    }
  }

  // Method to view details page based on detection type
  void _viewDetails() {
    if (_detectionResult == null) return;

    switch (_detectionType) {
      case DetectionType.plant:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => DiseaseDetailScreen(
              diseaseName:
                  _detectionResult!['disease_name'] ?? 'Unknown Disease',
              cropType: _selectedCrop,
              diseaseInfo: _detectionResult,
            ),
          ),
        );
        break;
      case DetectionType.insect:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => InsectDetailScreen(
              detectionResult: _detectionResult!,
              imageFile: _selectedImage!,
            ),
          ),
        );
        break;
      case DetectionType.bird:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => BirdDetailScreen(
              detectionResult: _detectionResult!,
              imageFile: _selectedImage!,
            ),
          ),
        );
        break;
    }
  }

  Widget _buildWeatherWidget() {
    if (_loadingWeather) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
      );
    }

    if (_currentWeather == null) {
      return Container(
          // Weather widget fallback
          );
    }

    // Extract weather data
    // (your existing weather widget implementation)
    return Container();
  }

  // Build detection type selector
  Widget _buildDetectionTypeSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to identify?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetectionTypeButton(
                  type: DetectionType.plant,
                  label: 'Plants',
                  icon: Icons.local_florist,
                  color: Colors.green,
                ),
                _buildDetectionTypeButton(
                  type: DetectionType.insect,
                  label: 'Insects',
                  icon: Icons.bug_report,
                  color: Colors.amber.shade800,
                ),
                _buildDetectionTypeButton(
                  type: DetectionType.bird,
                  label: 'Birds',
                  icon: Icons.flutter_dash,
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build individual detection type button
  Widget _buildDetectionTypeButton({
    required DetectionType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _detectionType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _detectionType = type;
            _detectionResult = null;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build crop selector (only visible for plant detection)
  Widget _buildCropSelector() {
    if (_detectionType != DetectionType.plant) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Crop Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingCrops)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedCrop,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _availableCrops.map((crop) {
                  return DropdownMenuItem(
                    value: crop,
                    child: Text(crop[0].toUpperCase() + crop.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCrop = value;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // Build result card
  Widget _buildResultCard() {
    if (_detectionResult == null) {
      return const SizedBox.shrink();
    }

    String title;
    String subtitle;
    Color color;

    switch (_detectionType) {
      case DetectionType.plant:
        title = _detectionResult!['disease_name'] ?? 'Unknown Disease';
        subtitle =
            'Confidence: ${((_detectionResult!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%';
        color = Colors.green;
        break;
      case DetectionType.insect:
        title = _detectionResult!['insect_name'] ?? 'Unknown Insect';
        subtitle =
            'Confidence: ${((_detectionResult!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%';
        color = Colors.amber.shade800;
        break;
      case DetectionType.bird:
        title = _detectionResult!['bird_name'] ?? 'Unknown Bird';
        subtitle =
            'Confidence: ${((_detectionResult!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%';
        color = Colors.blue.shade700;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _detectionType == DetectionType.plant
                        ? Icons.local_florist
                        : _detectionType == DetectionType.insect
                            ? Icons.bug_report
                            : Icons.flutter_dash,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection Result',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _viewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Details'),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
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
        title: Text(
          'BioScout Islamabad',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isLoggedIn)
            TextButton.icon(
              onPressed: _navigateToLogin,
              icon: Icon(Icons.person, color: Colors.green.shade800),
              label: Text(
                'Login',
                style: TextStyle(color: Colors.green.shade800),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Detection type selector
            _buildDetectionTypeSelector(),

            // Crop selector (only for plant detection)
            _buildCropSelector(),

            // Image upload section
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _captureImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: _selectedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      return const Center(
                                          child: Text('Error loading image'));
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  },
                                )
                              : Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _detectObject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getColorForDetectionType(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Processing...'),
                                  ],
                                )
                              : Text('Identify ${_getLabelForDetectionType()}'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Results card
            _buildResultCard(),

            // Weather widget
            //_buildWeatherWidget(),
          ],
        ),
      ),
    );
  }

  // Helper methods for UI
  String _getLabelForDetectionType() {
    switch (_detectionType) {
      case DetectionType.plant:
        return 'Plant Disease';
      case DetectionType.insect:
        return 'Insect';
      case DetectionType.bird:
        return 'Bird';
    }
  }

  Color _getColorForDetectionType() {
    switch (_detectionType) {
      case DetectionType.plant:
        return Colors.green.shade700;
      case DetectionType.insect:
        return Colors.amber.shade800;
      case DetectionType.bird:
        return Colors.blue.shade700;
    }
  }
}

extension on AppLocalizations? {
  get pleaseSelectLeafImage => null;

  get detectionResults => null;

  get weatherDataUnavailable => null;

  get optimalSprayTime => null;

  get retry => null;
}

// Extension method for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
