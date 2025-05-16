import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/disease_service.dart';
import '../services/weather_service.dart';
import 'new_login_screen.dart';
import 'community_screen.dart';
import 'disease_detail_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../screens/weather_details.dart';

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
  
  // Weather data
  bool _loadingWeather = true;
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _weatherForecast;
  Map<String, dynamic>? _sprayRecommendations;
  String _weatherUnits = 'metric';
  
  get _selectedDetectionType => null;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
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
        WeatherService.getCurrentWeather(position.latitude, position.longitude, units: _weatherUnits),
        WeatherService.getWeatherForecast(position.latitude, position.longitude, units: _weatherUnits),
        WeatherService.getSprayRecommendations(position.latitude, position.longitude, units: _weatherUnits),
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
          SnackBar(content: Text('Could not load weather data: ${e.toString()}')),
        );
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
  
  Future<void> _pickImage(dynamic DetectionType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Only validate leaf images when leaf detection is selected
      bool isValid = _selectedDetectionType == DetectionType.leaf 
          ? await _validateLeafImage(image)
          : true; // Skip validation for bird and insect detection
          
      if (isValid) {
        setState(() {
          _selectedImage = image;
          _detectionResult = null;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectLeafImage ?? 'Please select a leaf image')),
        );
      }
    }
  }

Future<void> _captureImage(dynamic DetectionType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Only validate leaf images when leaf detection is selected
      bool isValid = _selectedDetectionType == DetectionType.leaf 
          ? await _validateLeafImage(image)
          : true; // Skip validation for bird and insect detection
          
      if (isValid) {
        setState(() {
          _selectedImage = image;
          _detectionResult = null;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectLeafImage ?? 'Please select a leaf image')),
        );
      }
    }
  }

  Future<void> _detectSpecies(dynamic DetectionType) async {
    final localizations = AppLocalizations.of(context);
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.pleaseSelectImage ?? 'Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      Map<String, dynamic> result;
      
      // Choose the appropriate detection service based on selected type
      switch (_selectedDetectionType) {
        case DetectionType.leaf:
          if (kIsWeb) {
            final bytes = await _selectedImage!.readAsBytes();
            result = token != null 
                ? await DiseaseService.detectDiseaseWeb(bytes, token, cropType: _selectedCrop)
                : await DiseaseService.detectDiseaseAnonymousWeb(bytes, cropType: _selectedCrop);
          } else {
            final file = File(_selectedImage!.path);
            result = token != null
                ? await DiseaseService.detectDisease(file, token, cropType: _selectedCrop)
                : await DiseaseService.detectDiseaseAnonymousMobile(file, cropType: _selectedCrop);
          }
          break;
          
        case DetectionType.bird:
          if (kIsWeb) {
            final bytes = await _selectedImage!.readAsBytes();
            result = token != null 
                ? {'success': true, 'data': await BirdDetectionService.detectBirdSpeciesWeb(bytes, token)}
                : {'success': true, 'data': await BirdDetectionService.detectInsectSpeciesAnonymousWeb(bytes)};
          } else {
            final file = File(_selectedImage!.path);
            result = token != null
                ? {'success': true, 'data': await BirdDetectionService.detectBirdSpecies(file, token)}
                : {'success': true, 'data': await BirdDetectionService.detectBirdSpeciesAnonymous(file)};
          }
          break;
          
        case DetectionType.insect:
          if (kIsWeb) {
            final bytes = await _selectedImage!.readAsBytes();
            result = token != null 
                ? {'success': true, 'data': await InsectDetectionService.detectInsectSpeciesWeb(bytes, token)}
                : {'success': true, 'data': await InsectDetectionService.detectInsectSpeciesAnonymousWeb(bytes)};
          } else {
            final file = File(_selectedImage!.path);
            result = token != null
                ? {'success': true, 'data': await InsectDetectionService.detectInsectSpecies(file, token)}
                : {'success': true, 'data': await InsectDetectionService.detectInsectSpeciesAnonymous(file)};
          }
          break;
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

  void _viewDetailedInfo() {
    if (_detectionResult == null) return;
    
    switch (_selectedDetectionType) {
      case DetectionType.leaf:
        // Navigate to disease detail screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => DiseaseDetailScreen(
              diseaseName: _detectionResult!['disease'] ?? 'Unknown',
              cropType: _selectedCrop,
              diseaseInfo: _detectionResult!['disease_info'],
            ),
          ),
        );
        break;
        
      case DetectionType.bird:
      case DetectionType.insect:
        // Navigate to species detail screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => SpeciesDetailScreen(
              speciesName: _detectionResult!['species'] ?? 'Unknown',
              confidence: _detectionResult!['confidence'] ?? 0.0,
              detectionType: _selectedDetectionType.toString().split('.').last,
              detectionData: _detectionResult!,
            ),
          ),
        );
        break;
    }
  }

  // Update the build method to include detection type selection
  @override
  Widget build(BuildContext context) {
    // ... existing code ...
    
    return Scaffold(
      // ... existing code ...
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... existing code ...
            
            // Add detection type selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Detection Type:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<DetectionType>(
                    segments: [
                      ButtonSegment(
                        value: DetectionType.leaf,
                        label: Text('Leaf Disease'),
                        icon: Icon(Icons.eco),
                      ),
                      ButtonSegment(
                        value: DetectionType.bird,
                        label: Text('Bird Species'),
                        icon: Icon(Icons.flutter_dash),
                      ),
                      ButtonSegment(
                        value: DetectionType.insect,
                        label: Text('Insect Species'),
                        icon: Icon(Icons.bug_report),
                      ),
                    ],
                    selected: {_selectedDetectionType},
                    onSelectionChanged: (Set<DetectionType> selection) {
                      setState(() {
                        _selectedDetectionType = selection.first;
                        _detectionResult = null; // Clear previous results
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Show crop selector only for leaf disease detection
            if (_selectedDetectionType == DetectionType.leaf)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCropSelector(),
              ),
            
            // Image selection and preview
            // ... existing code ...
            
            // Update button text based on detection type
            ElevatedButton(
              onPressed: _isLoading ? null : _detectSpecies,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(_getDetectButtonText()),
            ),
            
            // Detection results
            if (_detectionResult != null) _buildDetectionResults(),
            
            // ... rest of the existing code ...
          ],
        ),
      ),
    );
  }
  
  String _getDetectButtonText() {
    switch (_selectedDetectionType) {
      case DetectionType.leaf:
        return 'Detect Disease';
      case DetectionType.bird:
        return 'Identify Bird';
      case DetectionType.insect:
        return 'Identify Insect';
    }
  }
  
  Widget _buildDetectionResults() {
    // Different result displays based on detection type
    switch (_selectedDetectionType) {
      case DetectionType.leaf:
        return _buildLeafDetectionResults();
      case DetectionType.bird:
        return _buildBirdDetectionResults();
      case DetectionType.insect:
        return _buildInsectDetectionResults();
    }
  }
  
  Widget _buildLeafDetectionResults() {
    // Existing leaf disease detection results display
    // ... existing code ...
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disease: ${_detectionResult!['disease'] ?? 'Unknown'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(_detectionResult!['confidence'] * 100).toStringAsFixed(2)}%',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _viewDetailedInfo,
            child: const Text('View Treatment Information'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBirdDetectionResults() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bird Species: ${_detectionResult!['species'] ?? 'Unknown'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(_detectionResult!['confidence'] * 100).toStringAsFixed(2)}%',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _viewDetailedInfo,
            child: const Text('View Species Information'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsectDetectionResults() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insect Species: ${_detectionResult!['species'] ?? 'Unknown'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(_detectionResult!['confidence'] * 100).toStringAsFixed(2)}%',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _viewDetailedInfo,
            child: const Text('View Species Information'),
          ),
        ],
      ),
    );
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
      if (fileSizeInMB > 10) { // Limit to 10MB
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


Future<void> _detectDisease() async {
    final localizations = AppLocalizations.of(context);
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.pleaseSelectImage ?? 'Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      Map<String, dynamic> result;
      
      if (kIsWeb) {
        // For web, we need to handle this differently
        final bytes = await _selectedImage!.readAsBytes();
        result = token != null 
            ? await DiseaseService.detectDiseaseWeb(bytes, token, cropType: _selectedCrop)
            : await DiseaseService.detectDiseaseAnonymousWeb(bytes, cropType: _selectedCrop);
      } else {
        // For mobile platforms
        final file = File(_selectedImage!.path);
        result = token != null
            ? await DiseaseService.detectDisease(file, token, cropType: _selectedCrop)
            : await DiseaseService.detectDiseaseAnonymousMobile(file, cropType: _selectedCrop);
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

   Widget _buildWeatherWidget() {
    if (_loadingWeather) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentWeather == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.weatherDataUnavailable ?? 'Weather data unavailable',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              TextButton(
                onPressed: _loadWeatherData,
                child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract weather data
    final temp = _currentWeather!['temperature'];
    final condition = _currentWeather!['weather_condition'] ?? 'unknown';
    final description = _currentWeather!['weather_description'] ?? 'Unknown';
    final iconCode = _currentWeather!['weather_icon'] ?? '01d';
    final windSpeed = _currentWeather!['wind_speed'];
    final windDirection = _currentWeather!['wind_direction'];
    final locationName = _currentWeather!['location_name'];
    final country = _currentWeather!['country'];
    
    // Format data
    final formattedTemp = WeatherService.formatTemperature(temp, _weatherUnits);
    final windDirectionText = WeatherService.getWindDirection(windDirection);
    final iconUrl = WeatherService.getWeatherIconUrl(iconCode);
    
    // Get spray recommendations
    final hasOptimalTimes = _sprayRecommendations != null && 
                           _sprayRecommendations!.containsKey('optimal_times') && 
                           _sprayRecommendations!['optimal_times'] != null &&
                           (_sprayRecommendations!['optimal_times'] as List).isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => WeatherDetailsScreen(
              currentWeather: _currentWeather!,
              weatherForecast: _weatherForecast,
              sprayRecommendations: _sprayRecommendations,
              weatherUnits: _weatherUnits,
              refreshCallback: _loadWeatherData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade500, Colors.blue.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$locationName, $country',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedTemp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.network(
                    iconUrl,
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.cloud,
                        color: Colors.white,
                        size: 60,
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.air, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${windSpeed.toStringAsFixed(1)} ${_weatherUnits == 'imperial' ? 'mph' : 'm/s'} $windDirectionText',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  if (hasOptimalTimes)
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)?.optimalSprayTime ?? 'Optimal spray time available',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
  
  Widget _buildWeatherIcon(String iconCode) {
    // Custom weather icon based on the code
    IconData iconData;
    Color iconColor = Colors.white;
    double size = 60.0;
    
    if (iconCode.contains('01')) {
      // Clear sky
      iconData = iconCode.contains('d') 
          ? Icons.wb_sunny_rounded
          : Icons.nightlight_round;
      iconColor = iconCode.contains('d') ? Colors.amber : Colors.white;
    } else if (iconCode.contains('02')) {
      // Few clouds
      iconData = iconCode.contains('d')
          ? Icons.cloud_queue_rounded
          : Icons.nights_stay_rounded;
    } else if (iconCode.contains('03') || iconCode.contains('04')) {
      // Scattered or broken clouds
      iconData = Icons.cloud_rounded;
    } else if (iconCode.contains('09')) {
      // Shower rain
      iconData = Icons.grain_rounded;
      iconColor = Colors.lightBlue.shade100;
    } else if (iconCode.contains('10')) {
      // Rain
      iconData = Icons.water_drop_rounded;
      iconColor = Colors.lightBlue.shade100;
    } else if (iconCode.contains('11')) {
      // Thunderstorm
      iconData = Icons.flash_on_rounded;
      iconColor = Colors.amber;
    } else if (iconCode.contains('13')) {
      // Snow
      iconData = Icons.ac_unit_rounded;
    } else if (iconCode.contains('50')) {
      // Mist/fog
      iconData = Icons.waves_rounded;
    } else {
      // Default
      iconData = Icons.cloud_rounded;
    }
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: size,
      ),
    );
  }
  
  
  Widget _buildWeatherEffects(String condition, bool isNight) {
    // This is a simplified version to avoid rendering issues
    return const SizedBox.shrink();
  }
  
  Color _getWeatherShadowColor(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('clear') || condition.contains('sun')) {
      return Colors.blue.withOpacity(0.3);
    } else if (condition.contains('cloud')) {
      return Colors.blueGrey.withOpacity(0.3);
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return Colors.indigo.withOpacity(0.3);
    } else if (condition.contains('thunder')) {
      return Colors.deepPurple.withOpacity(0.3);
    } else if (condition.contains('snow')) {
      return Colors.blueGrey.withOpacity(0.3);
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return Colors.grey.withOpacity(0.3);
    } else {
      return Colors.green.withOpacity(0.3);
    }
  }
  
  List<Color> _getWeatherGradient(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('clear') || condition.contains('sun')) {
      return [
        const Color(0xFF1E88E5),
        const Color(0xFF64B5F6),
      ];
    } else if (condition.contains('cloud')) {
      return [
        const Color(0xFF546E7A),
        const Color(0xFF78909C),
      ];
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return [
        const Color(0xFF1A237E),
        const Color(0xFF303F9F),
      ];
    } else if (condition.contains('thunder')) {
      return [
        const Color(0xFF1A237E),
        const Color(0xFF0D47A1),
      ];
    } else if (condition.contains('snow')) {
      return [
        const Color(0xFF546E7A),
        const Color(0xFF90A4AE),
      ];
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return [
        const Color(0xFF616161),
        const Color(0xFF9E9E9E),
      ];
    } else {
      // Default gradient
      return [
        const Color(0xFF43A047),
        const Color(0xFF66BB6A),
      ];
    }
  }
  
  Widget _buildWeatherInfoItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionResult() {
    final localizations = AppLocalizations.of(context);
    if (_detectionResult == null ||
        _detectionResult!['prediction'] == null ||
        _detectionResult!['probabilities'] == null) {
      return const SizedBox();
    }

    final prediction = _detectionResult!['prediction'] as String;
    final probabilities = _detectionResult!['probabilities'] as Map<String, dynamic>;
    final diseaseInfo = _detectionResult!['disease_info'] as Map<String, dynamic>?;

    // Sort probabilities by value in descending order
    final sortedProbabilities = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
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
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.eco, color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations?.detectionResults ?? "Detection Results",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prediction,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Disease info preview
            if (diseaseInfo != null)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Disease Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diseaseInfo['description'].toString().length > 120
                                ? '${diseaseInfo['description'].toString().substring(0, 120)}...'
                                : diseaseInfo['description'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              // Navigate to disease detail screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DiseaseDetailScreen(
                                    diseaseName: prediction,
                                    cropType: _selectedCrop,
                                    diseaseInfo: diseaseInfo,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 16, color: Colors.blue.shade700),
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
            
            // Probabilities section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        localizations?.probabilities ?? "Probabilities",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...sortedProbabilities.take(5).map((entry) {
                    final percentage = (entry.value * 100).toStringAsFixed(1);
                    final isTopPrediction = entry.key == prediction;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isTopPrediction ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isTopPrediction ? Colors.green.shade200 : Colors.grey.shade200,
                        ),
                        boxShadow: isTopPrediction ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isTopPrediction ? FontWeight.bold : FontWeight.normal,
                                    color: isTopPrediction ? Colors.green[800] : Colors.grey[800],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isTopPrediction ? Colors.green.shade100 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isTopPrediction ? Colors.green[800] : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: entry.value,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isTopPrediction 
                                          ? [Colors.green.shade300, Colors.green.shade500]
                                          : [Colors.blue.shade300, Colors.blue.shade500],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: isTopPrediction ? [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ] : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImage == null) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (kIsWeb)
              // For web platforms
              FutureBuilder<Uint8List>(
                future: _selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && 
                      snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              )
            else
              // For mobile platforms
              Image.file(
                File(_selectedImage!.path),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            
            // Overlay gradient for better text visibility if needed
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Selected Image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuth;
    final username = authProvider.username;
    final localizations = AppLocalizations.of(context);
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
          'BioScout Islamabad',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
      ],
    ),
    actionsIconTheme: IconThemeData(color: Colors.green.shade800),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadWeatherData,
        tooltip: 'Refresh weather',
        splashRadius: 24,
      ),
      IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => (context),
        splashRadius: 24,
      ),
    ],
  ),

           drawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade700,
                  ],
                ),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco, size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLoggedIn 
                        ? 'Hello, ${username ?? ""}!' 
                        : (localizations?.welcomeMessage ?? 'Welcome to BioScout Islamabad!'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoggedIn 
                        ? 'Glad to see you again!' 
                        : 'Sign in to access all features',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: localizations?.community ?? 'Community',
                    onTap: () {
                      Navigator.pop(context);
                      if (isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CommunityScreen()),
                        );
                      } else {
                        _showLoginDialog(context);
                      }
                    },
                  ),
                  if (!isLoggedIn)
                    _buildDrawerItem(
                      icon: Icons.login_rounded,
                      title: localizations?.login ?? 'Login',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewLoginScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'BioScout Islamabad v1.0.0',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with welcome message and title
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn 
                        ? 'Welcome, ${username ?? ""}!' 
                        : (localizations?.welcomeMessage ?? 'Welcome to BioScout Islamabad!'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations?.detectDisease ?? 'Identify Crop Diseases',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations?.uploadLeafImage ?? 'Upload a leaf image to detect diseases and get instant results',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Weather widget instead of crop selector
            _buildWeatherWidget(),
            
            // Image display
            AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _selectedImage != null
      ? _buildImageDisplay()
      : Container(
          margin: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade100.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_search,
                  size: 64,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations?.uploadLeafImage ?? 'Upload a leaf image',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
),

// Image selection buttons (Select & Capture)
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            localizations?.selectImage ?? 'Select Image',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 6,
            backgroundColor: Colors.white,
            foregroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.shade100),
            ),
            shadowColor: Colors.green.withOpacity(0.12),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _captureImage,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(
            localizations?.captureImage ?? 'Capture Image',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 6,
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Colors.green.withOpacity(0.25),
          ),
        ),
      ),
    ],
  ),
),

// Detect disease button (Primary CTA)
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isLoading ? null : _detectDisease,
    style: ElevatedButton.styleFrom(
      elevation: 8,
      backgroundColor: Colors.green.shade700,
      disabledBackgroundColor: Colors.green.shade300,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.green.withOpacity(0.3),
    ),
    child: _isLoading
        ? const SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            localizations?.detectDisease ?? 'Detect Disease',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
  ),
),


            
            // Detection result
            _buildDetectionResult(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
 Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.green : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations?.joinCommunity ?? 'Join Community',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                // Replace with a hardcoded string since the key doesn't exist
                'You need to be logged in to access the community features. Would you like to login or register now?',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewLoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(localizations?.login ?? 'Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Helper method to extract optimal spray time text
  String _getOptimalSprayTimeText(Map<String, dynamic>? sprayRecommendations) {
    if (sprayRecommendations == null || 
        !sprayRecommendations.containsKey('optimal_times') || 
        sprayRecommendations['optimal_times'] == null ||
        (sprayRecommendations['optimal_times'] as List).isEmpty) {
      return 'No optimal spray times available';
    }
    
    final optimalTime = sprayRecommendations['optimal_times'][0] as Map<String, dynamic>;
    final formattedTime = optimalTime['formatted_time'] as String? ?? 'Unknown time';
    
    // Handle reasons as either String or List
    String reasonsText;
    if (optimalTime['reasons'] is List) {
      reasonsText = (optimalTime['reasons'] as List).join(', ');
    } else if (optimalTime['reasons'] is String) {
      reasonsText = optimalTime['reasons'] as String;
    } else {
      reasonsText = 'Favorable conditions expected';
    }
    
    return '$formattedTime - $reasonsText';
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


