import 'package:geolocator/geolocator.dart';

/// Location Service for GPS-based location detection
class LocationService {
  /// Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentCity;
  String? _currentProvince;

  Position? get currentPosition => _currentPosition;
  String? get currentCity => _currentCity;
  String? get currentProvince => _currentProvince;

  /// Check if location services are enabled and request permission
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Determine city/province from coordinates
      await _reverseGeocode(_currentPosition!);

      return _currentPosition;
    } catch (e) {
      print('[Location] Error getting location: $e');
      return null;
    }
  }

  /// Reverse geocode to get city name from coordinates
  /// Using a simple mapping for Nepal regions based on coordinates
  Future<void> _reverseGeocode(Position position) async {
    final lat = position.latitude;
    final lon = position.longitude;

    // Nepal region mapping based on approximate coordinates
    _currentCity = _getCityFromCoordinates(lat, lon);
    _currentProvince = _getProvinceFromCoordinates(lat, lon);
  }

  /// Get city name from coordinates (simplified mapping for Nepal)
  String _getCityFromCoordinates(double lat, double lon) {
    // Kathmandu Valley area
    if (lat >= 27.6 && lat <= 27.8 && lon >= 85.2 && lon <= 85.5) {
      if (lon < 85.32) return 'Kathmandu';
      if (lat < 27.68) return 'Lalitpur';
      return 'Bhaktapur';
    }

    // Pokhara area
    if (lat >= 28.1 && lat <= 28.3 && lon >= 83.9 && lon <= 84.1) {
      return 'Pokhara';
    }

    // Biratnagar area
    if (lat >= 26.4 && lat <= 26.5 && lon >= 87.2 && lon <= 87.3) {
      return 'Biratnagar';
    }

    // Birgunj area
    if (lat >= 26.95 && lat <= 27.1 && lon >= 84.8 && lon <= 85.0) {
      return 'Birgunj';
    }

    // Bharatpur area
    if (lat >= 27.6 && lat <= 27.8 && lon >= 84.3 && lon <= 84.5) {
      return 'Bharatpur';
    }

    // Dhangadhi area
    if (lat >= 28.65 && lat <= 28.75 && lon >= 80.5 && lon <= 80.7) {
      return 'Dhangadhi';
    }

    // Nepalgunj area
    if (lat >= 28.0 && lat <= 28.1 && lon >= 81.5 && lon <= 81.7) {
      return 'Nepalgunj';
    }

    // Default to general area based on province
    return _getProvinceFromCoordinates(lat, lon);
  }

  /// Get province from coordinates
  String _getProvinceFromCoordinates(double lat, double lon) {
    // Nepal boundaries: lat 26.3-30.4, lon 80.0-88.2

    // Bagmati Province (central with Kathmandu)
    if (lat >= 27.3 && lat <= 28.2 && lon >= 84.5 && lon <= 86.2) {
      return 'Bagmati';
    }

    // Gandaki Province (Pokhara area)
    if (lat >= 27.5 && lat <= 29.3 && lon >= 83.5 && lon <= 85.0) {
      return 'Gandaki';
    }

    // Koshi Province (eastern)
    if (lat >= 26.3 && lat <= 27.8 && lon >= 86.5 && lon <= 88.2) {
      return 'Koshi';
    }

    // Madhesh Province (southern terai)
    if (lat >= 26.3 && lat <= 27.2 && lon >= 85.0 && lon <= 87.0) {
      return 'Madhesh';
    }

    // Lumbini Province
    if (lat >= 27.0 && lat <= 28.5 && lon >= 82.5 && lon <= 84.0) {
      return 'Lumbini';
    }

    // Karnali Province
    if (lat >= 28.5 && lat <= 30.0 && lon >= 81.5 && lon <= 83.5) {
      return 'Karnali';
    }

    // Sudurpashchim Province (far western)
    if (lat >= 28.0 && lat <= 30.5 && lon >= 80.0 && lon <= 81.5) {
      return 'Sudurpashchim';
    }

    return 'Nepal';
  }

  /// Get location summary for display
  String getLocationSummary() {
    if (_currentCity != null && _currentProvince != null) {
      return '$_currentCity, $_currentProvince';
    } else if (_currentCity != null) {
      return _currentCity!;
    } else if (_currentProvince != null) {
      return _currentProvince!;
    }
    return 'Nepal';
  }
}

/// Global instance
final locationService = LocationService();
