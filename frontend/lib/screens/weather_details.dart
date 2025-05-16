import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/weather_service.dart';
import 'package:intl/intl.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> currentWeather;
  final Map<String, dynamic>? weatherForecast;
  final Map<String, dynamic>? sprayRecommendations;
  final String weatherUnits;
  final Function refreshCallback;

  const WeatherDetailsScreen({
    Key? key,
    required this.currentWeather,
    this.weatherForecast,
    this.sprayRecommendations,
    required this.weatherUnits,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract weather data
    final temp = currentWeather['temperature'];
    final feelsLike = currentWeather['feels_like'];
    final condition = currentWeather['weather_condition'] ?? 'unknown';
    final description = currentWeather['weather_description'] ?? 'Unknown';
    final iconCode = currentWeather['weather_icon'] ?? '01d';
    final humidity = currentWeather['humidity'];
    final pressure = currentWeather['pressure'];
    final windSpeed = currentWeather['wind_speed'];
    final windDirection = currentWeather['wind_direction'];
    final locationName = currentWeather['location_name'] ?? 'Unknown';
    final country = currentWeather['country'] ?? '';
    final sunrise = currentWeather['sunrise'];
    final sunset = currentWeather['sunset'];
    final visibility = currentWeather['visibility'];
    final cloudiness = currentWeather['cloudiness'];
    
    // Format data
    final formattedTemp = WeatherService.formatTemperature(temp, weatherUnits);
    final formattedFeelsLike = WeatherService.formatTemperature(feelsLike, weatherUnits);
    final windDirectionText = WeatherService.getWindDirection(windDirection);
    final iconUrl = WeatherService.getWeatherIconUrl(iconCode);
    
    // Format sunrise/sunset times
    final sunriseTime = sunrise != null 
        ? DateTime.fromMillisecondsSinceEpoch(sunrise * 1000)
        : null;
    final sunsetTime = sunset != null 
        ? DateTime.fromMillisecondsSinceEpoch(sunset * 1000)
        : null;
    final timeFormat = DateFormat('HH:mm');
    
    // Get forecast data
    final hasForecast = weatherForecast != null && 
                        weatherForecast!.containsKey('list') && 
                        (weatherForecast!['list'] as List).isNotEmpty;
    
    // Get spray recommendations
    final hasOptimalTimes = sprayRecommendations != null && 
                           sprayRecommendations!.containsKey('optimal_times') && 
                           sprayRecommendations!['optimal_times'] != null &&
                           (sprayRecommendations!['optimal_times'] as List).isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with weather header
          SliverAppBar(
            expandedHeight: 301,  // Increase by 1 pixel to accommodate the overflow
            pinned: true,
            stretch: true,
            backgroundColor: _getWeatherColor(condition),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _getWeatherGradient(condition),
                  ),
                  image: DecorationImage(
                    image: AssetImage(_getWeatherBackgroundImage(condition)),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(  // Add this wrapper
                    physics: const NeverScrollableScrollPhysics(),  // Prevent actual scrolling
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,  // Add this to minimize height
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          '$locationName, $country',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          iconUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          formattedTemp,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          description.toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Feels like $formattedFeelsLike',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => refreshCallback(),
                tooltip: 'Refresh weather data',
              ),
            ],
          ),
          
          // Weather details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current conditions card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Conditions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(Icons.water_drop_outlined, '${humidity ?? 0}%', 'Humidity', Colors.blue),
                              _buildDetailItem(Icons.compress, '${pressure ?? 0} hPa', 'Pressure', Colors.purple),
                              _buildDetailItem(
                                Icons.visibility, 
                                visibility != null ? '${(visibility / 1000).toStringAsFixed(1)} km' : 'N/A', 
                                'Visibility'
                              , Colors.teal),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(Icons.air, '${windSpeed ?? 0} ${weatherUnits == 'imperial' ? 'mph' : 'm/s'}', 'Wind Speed', Colors.blue),
                              _buildDetailItem(Icons.explore_outlined, windDirectionText ?? 'N/A', 'Wind Direction', Colors.orange),
                              _buildDetailItem(Icons.cloud, '${cloudiness ?? 0}%', 'Cloudiness', Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sun times card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sun Times',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(Icons.wb_sunny, sunriseTime != null ? timeFormat.format(sunriseTime) : '--:--', 'Sunrise', Colors.orange),
                              _buildDetailItem(Icons.nightlight_round, sunsetTime != null ? timeFormat.format(sunsetTime) : '--:--', 'Sunset', Colors.deepPurple),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Forecast section
                  if (hasForecast) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Forecast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (weatherForecast!['list'] as List).take(8).length,
                        itemBuilder: (context, index) {
                          final forecastItem = weatherForecast!['list'][index];
                          final forecastTemp = forecastItem['main']['temp'];
                          final forecastIcon = forecastItem['weather'][0]['icon'];
                          final forecastDesc = forecastItem['weather'][0]['description'];
                          final forecastDt = forecastItem['dt'];
                          final forecastTime = DateTime.fromMillisecondsSinceEpoch(forecastDt * 1000);
                          
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E').format(forecastTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(forecastTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  WeatherService.getWeatherIconUrl(forecastIcon),
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  WeatherService.formatTemperature(forecastTemp, weatherUnits),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  forecastDesc.toString().capitalize(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Spray recommendations
                  if (hasOptimalTimes) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Optimal Spray Times',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (sprayRecommendations!['optimal_times'] as List).length,
                      itemBuilder: (context, index) {
                        final timeData = sprayRecommendations!['optimal_times'][index] as Map<String, dynamic>;
                        final formattedTime = timeData['formatted_time'] as String? ?? 'Unknown time';
                        
                        // Fix for the TypeError - Handle reasons as either String or List
                        String reasonsText;
                        if (timeData['reasons'] is List) {
                          reasonsText = (timeData['reasons'] as List).join(', ');
                        } else if (timeData['reasons'] is String) {
                          reasonsText = timeData['reasons'] as String;
                        } else {
                          reasonsText = 'Favorable conditions';
                        }
                        
                        final conditions = timeData['conditions'] != null 
                            ? timeData['conditions'] as Map<String, dynamic>
                            : <String, dynamic>{
                                'temperature': 0,
                                'humidity': 0,
                                'wind_speed': 0,
                                'weather_condition': 'Unknown'
                              };
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.schedule,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            reasonsText,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildSprayCondition(
                                      Icons.thermostat, 
                                      '${conditions['temperature'] ?? 0}°${weatherUnits == 'imperial' ? 'F' : 'C'}',
                                      'Temperature',
                                      Colors.orange,
                                    ),
                                    _buildSprayCondition(
                                      Icons.water_drop, 
                                      '${conditions['humidity'] ?? 0}%',
                                      'Humidity',
                                      Colors.blue,
                                    ),
                                    _buildSprayCondition(
                                      Icons.air, 
                                      '${conditions['wind_speed'] ?? 0} ${weatherUnits == 'imperial' ? 'mph' : 'm/s'}',
                                      'Wind Speed',
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Dummy optimal spray time when no data is available
                    const SizedBox(height: 24),
                    const Text(
                      'Optimal Spray Times',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.schedule,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tomorrow at 6:00 AM',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Ideal weather conditions for spraying',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSprayCondition(
                                  Icons.thermostat, 
                                  '24°${weatherUnits == 'imperial' ? 'F' : 'C'}',
                                  'Temperature',
                                  Colors.orange,
                                ),
                                _buildSprayCondition(
                                  Icons.water_drop, 
                                  '45%',
                                  'Humidity',
                                  Colors.blue,
                                ),
                                _buildSprayCondition(
                                  Icons.air, 
                                  '3.5 ${weatherUnits == 'imperial' ? 'mph' : 'm/s'}',
                                  'Wind Speed',
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSprayCondition(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade800,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  String _getWeatherBackgroundImage(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('clear') || condition.contains('sun')) {
      return 'assets/images/clear_sky.jpg';
    } else if (condition.contains('cloud')) {
      return 'assets/images/cloudy.jpg';
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'assets/images/rain.jpg';
    } else if (condition.contains('thunder')) {
      return 'assets/images/thunderstorm.jpg';
    } else if (condition.contains('snow')) {
      return 'assets/images/snow.jpg';
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return 'assets/images/fog.jpg';
    } else {
      return 'assets/images/default_weather.jpg';
    }
  }
  
  Color _getWeatherColor(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('clear') || condition.contains('sun')) {
      return const Color(0xFF1E88E5);
    } else if (condition.contains('cloud')) {
      return const Color(0xFF546E7A);
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return const Color(0xFF1A237E);
    } else if (condition.contains('thunder')) {
      return const Color(0xFF1A237E);
    } else if (condition.contains('snow')) {
      return const Color(0xFF546E7A);
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return const Color(0xFF616161);
    } else {
      return const Color(0xFF43A047);
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
      return [
        const Color(0xFF43A047),
        const Color(0xFF66BB6A),
      ];
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}