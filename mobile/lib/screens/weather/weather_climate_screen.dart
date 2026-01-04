import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';

/// Full weather, climate, and air quality details screen
class WeatherClimateScreen extends StatefulWidget {
  const WeatherClimateScreen({super.key});

  @override
  State<WeatherClimateScreen> createState() => _WeatherClimateScreenState();
}

class _WeatherClimateScreenState extends State<WeatherClimateScreen> {
  Map<String, dynamic>? _combinedData;
  Map<String, dynamic>? _pollenData; // Pollen/allergy data
  bool _isLoading = true;
  String _userLocation = 'nepal';
  String? _userCity; // Display city name

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _userCity = user.city;
      // Map city/province to country - for Nepal cities, use 'nepal'
      // Could be extended to support more countries
      _userLocation = _getCountryFromCity(user.city, user.province);
    }
    _loadData();
  }

  String _getCountryFromCity(String? city, String? province) {
    // Map Nepal provinces/cities to 'nepal'
    // This can be extended for other countries
    final nepalProvinces = [
      'bagmati',
      'gandaki',
      'lumbini',
      'karnali',
      'sudurpashchim',
      'madhesh',
      'koshi',
      'province 1',
      'province 2',
      'kathmandu',
      'pokhara',
      'lalitpur',
      'bhaktapur',
      'biratnagar',
      'birgunj'
    ];

    final loc = (city ?? province ?? 'nepal').toLowerCase();
    if (nepalProvinces.any((p) => loc.contains(p)) || loc.contains('nepal')) {
      return 'nepal';
    }
    // Default to nepal for now
    return 'nepal';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiService.getCombinedHealthData(_userLocation);
      final pollen = await apiService.getPollenData(_userLocation);

      // Cache for offline use
      await OfflineCacheService.cacheWeather(data);

      setState(() {
        _combinedData = data;
        _pollenData = pollen;
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache on error
      final cachedData = OfflineCacheService.getCachedWeather();
      if (cachedData != null) {
        setState(() {
          _combinedData = cachedData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        }
      }
    }
  }

  void _openAIAnalysis() {
    if (_combinedData == null) return;

    final weather = _combinedData!['weather']?['current'];
    final airQuality = _combinedData!['air_quality']?['current'];

    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: 'Environmental Health Expert',
        patientContext:
            '''Current conditions in ${_userCity ?? _userLocation.toUpperCase()}:
        
WEATHER:
- Temperature: ${weather?['temperature'] ?? 'N/A'}°C
- Humidity: ${weather?['humidity'] ?? 'N/A'}%
- Conditions: ${weather?['weather_description'] ?? 'N/A'}
- Wind: ${weather?['wind_speed'] ?? 'N/A'} m/s

AIR QUALITY:
- AQI: ${airQuality?['aqi'] ?? 'N/A'}
- PM2.5: ${airQuality?['pm2_5'] ?? 'N/A'} μg/m³
- PM10: ${airQuality?['pm10'] ?? 'N/A'} μg/m³

The user wants to know how these conditions affect their health.''',
        systemPrompt:
            '''You are an environmental health expert. Analyze the current weather and air quality conditions and provide:
1. Health impact assessment
2. Specific recommendations for sensitive groups (elderly, children, respiratory patients)
3. Outdoor activity guidance
4. Protective measures if air quality is poor''',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.weatherAirQuality),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Health Analysis',
            onPressed: _combinedData != null ? _openAIAnalysis : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _combinedData == null
              ? const Center(child: Text('Unable to load data'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWeatherCard(),
                        const SizedBox(height: 16),
                        _buildAirQualityCard(),
                        const SizedBox(height: 16),
                        _buildPollenCard(), // Pollen/allergy data
                        const SizedBox(height: 16),
                        _buildHealthRecommendations(),
                        const SizedBox(height: 16),
                        _buildDetailedMetrics(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _combinedData!['weather'] as Map<String, dynamic>?;
    final current = weather?['current'] as Map<String, dynamic>?;
    if (weather == null || current == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Weather data unavailable'),
        ),
      );
    }

    final temp = current['temperature'] ?? 0;
    final humidity = current['humidity'] ?? 0;
    final description = current['weather_description'] ?? 'Unknown';
    final windSpeed = current['wind_speed'] ?? 0;
    final feelsLike = current['feels_like'] ?? temp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const Icon(Icons.wb_sunny, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${temp.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                      Text(
                        'Feels like ${feelsLike.toStringAsFixed(1)}°C',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildWeatherStat(Icons.water_drop, 'Humidity', '$humidity%'),
                _buildWeatherStat(
                    Icons.air, 'Wind', '${windSpeed.toStringAsFixed(1)} m/s'),
                _buildWeatherStat(Icons.visibility, 'Visibility',
                    '${weather['visibility'] ?? 'N/A'} km'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAirQualityCard() {
    final airQuality = _combinedData!['air_quality'] as Map<String, dynamic>?;
    final current = airQuality?['current'] as Map<String, dynamic>?;
    if (airQuality == null || current == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Air quality data unavailable'),
        ),
      );
    }

    final aqi = current['aqi'] ?? 0;
    final aqiLevel = _getAQILevel(aqi);
    final aqiColor = _getAQIColor(aqi);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.air, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Air Quality Index',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: aqiColor.withOpacity(0.2),
                    border: Border.all(color: aqiColor, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      aqi.toString(),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: aqiColor),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aqiLevel,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: aqiColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getAQIDescription(aqi),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Pollutant levels
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildPollutantChip('PM2.5', current['pm2_5'] ?? 0, 'μg/m³'),
                _buildPollutantChip('PM10', current['pm10'] ?? 0, 'μg/m³'),
                _buildPollutantChip('O₃', current['ozone'] ?? 0, 'μg/m³'),
                _buildPollutantChip(
                    'NO₂', current['nitrogen_dioxide'] ?? 0, 'μg/m³'),
                _buildPollutantChip(
                    'CO', current['carbon_monoxide'] ?? 0, 'μg/m³'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollutantChip(String name, dynamic value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text('${value.toString()} $unit',
              style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildPollenCard() {
    if (_pollenData == null) return const SizedBox.shrink();

    final current = _pollenData!['current'] as Map<String, dynamic>?;
    final risk = _pollenData!['pollen_risk'] as Map<String, dynamic>?;
    final alerts = _pollenData!['health_alerts'] as List<dynamic>? ?? [];

    if (current == null) return const SizedBox.shrink();

    Color getRiskColor(String? level) {
      switch (level) {
        case 'very_low':
          return Colors.green;
        case 'low':
          return Colors.lightGreen;
        case 'moderate':
          return Colors.orange;
        case 'high':
          return Colors.deepOrange;
        case 'very_high':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    final riskLevel = risk?['level'] ?? 'unknown';
    final riskColor = getRiskColor(riskLevel);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass, color: riskColor, size: 24),
                const SizedBox(width: 10),
                const Text('Pollen & Allergy',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    riskLevel.toString().toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                        color: riskColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Risk message
            Text(
              risk?['message'] ?? 'Check pollen levels',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Pollen types
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPollenChip('🌾 Grass', current['grass_pollen']),
                _buildPollenChip('🌳 Birch', current['birch_pollen']),
                _buildPollenChip('🌿 Ragweed', current['ragweed_pollen']),
                if (current['dust'] != null && (current['dust'] as num) > 0)
                  _buildPollenChip('💨 Dust', current['dust']),
              ],
            ),

            // Health alerts
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...alerts.take(3).map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(alert['icon'] ?? '⚠️',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert['message'] ?? '',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPollenChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '${(value as num?)?.toInt() ?? 0}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecommendations() {
    final aqCurrent = (_combinedData!['air_quality']
        as Map<String, dynamic>?)?['current'] as Map<String, dynamic>?;
    final aqi = aqCurrent?['aqi'] ?? 50;
    final weatherCurrent = (_combinedData!['weather']
        as Map<String, dynamic>?)?['current'] as Map<String, dynamic>?;
    final temp = weatherCurrent?['temperature'] ?? 20;

    final recommendations = <Map<String, dynamic>>[];

    // AQI-based recommendations
    if (aqi > 100) {
      recommendations.add({
        'icon': Icons.masks,
        'title': 'Wear a Mask',
        'description':
            'Air quality is unhealthy. Consider wearing an N95 mask outdoors.',
        'color': Colors.red,
      });
    }
    if (aqi > 150) {
      recommendations.add({
        'icon': Icons.home,
        'title': 'Stay Indoors',
        'description': 'Limit outdoor activities. Keep windows closed.',
        'color': Colors.orange,
      });
    }

    // Temperature-based recommendations
    if (temp > 35) {
      recommendations.add({
        'icon': Icons.water_drop,
        'title': 'Stay Hydrated',
        'description':
            'High temperature. Drink plenty of water and avoid direct sunlight.',
        'color': Colors.blue,
      });
    }
    if (temp < 10) {
      recommendations.add({
        'icon': Icons.ac_unit,
        'title': 'Keep Warm',
        'description': 'Cold conditions. Dress in layers and stay warm.',
        'color': Colors.cyan,
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.check_circle,
        'title': 'Conditions are Good',
        'description':
            'Weather and air quality are favorable for outdoor activities.',
        'color': Colors.green,
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Health Recommendations',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (r['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(r['icon'] as IconData,
                            color: r['color'] as Color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(r['description'] as String,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    final weather = _combinedData!['weather'] as Map<String, dynamic>?;
    final current = weather?['current'] as Map<String, dynamic>?;
    final forecast = weather?['forecast'] as List<dynamic>?;
    final todayForecast = forecast?.isNotEmpty == true
        ? forecast![0] as Map<String, dynamic>
        : null;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.analytics, color: AppColors.primary),
        title: const Text('Detailed Metrics'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMetricRow('UV Index',
                    todayForecast?['uv_index']?.toString() ?? 'N/A'),
                _buildMetricRow('Feels Like',
                    '${current?['feels_like']?.toStringAsFixed(1) ?? 'N/A'}°C'),
                _buildMetricRow(
                    'Precipitation', '${current?['precipitation'] ?? 0} mm'),
                _buildMetricRow('Today High',
                    '${todayForecast?['temp_max']?.toStringAsFixed(1) ?? 'N/A'}°C'),
                _buildMetricRow('Today Low',
                    '${todayForecast?['temp_min']?.toStringAsFixed(1) ?? 'N/A'}°C'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getAQILevel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy (Sensitive)';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown.shade800;
  }

  String _getAQIDescription(int aqi) {
    if (aqi <= 50) return 'Air quality is satisfactory.';
    if (aqi <= 100) return 'Acceptable for most people.';
    if (aqi <= 150) return 'Sensitive groups may be affected.';
    if (aqi <= 200) return 'Everyone may experience health effects.';
    if (aqi <= 300) return 'Health alert: serious effects possible.';
    return 'Health emergency conditions!';
  }
}
