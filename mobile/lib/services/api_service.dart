import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class ApiService {
  // Change this to your computer's IP address on the same network
  static const String baseUrl = 'https://aacademyapi.ashlya.com/api';
  final Box _settingsBox = Hive.box('settings');

  String? get _accessToken => _settingsBox.get('access_token');

  Map<String, String> get _headers {
    final token = _accessToken;
    print(
        '[API DEBUG] Token present: ${token != null}, Token length: ${token?.length ?? 0}');
    if (token != null) {
      print(
          '[API DEBUG] Token first 20 chars: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    }
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    await _settingsBox.put('access_token', accessToken);
    if (refreshToken != null) {
      await _settingsBox.put('refresh_token', refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _settingsBox.delete('access_token');
    await _settingsBox.delete('refresh_token');
  }

  bool get isLoggedIn => _accessToken != null;

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else {
      final error = response.body.isNotEmpty
          ? json.decode(response.body)
          : {'error': 'Request failed'};
      throw Exception(error['error'] ?? 'Request failed');
    }
  }

  Future<List<dynamic>> _handleListResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Request failed');
    }
  }

  // ==================== AUTH ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(response);
    if (data['access_token'] != null) {
      await saveTokens(data['access_token'], data['refresh_token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> googleSignIn({
    required String email,
    required String name,
    required String googleId,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'name': name,
        'google_id': googleId,
        'photo_url': photoUrl,
      }),
    );
    final data = await _handleResponse(response);
    if (data['access_token'] != null) {
      await saveTokens(data['access_token'], data['refresh_token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName, {
    int? age,
    String? location,
    String? language,
    String? role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'full_name': fullName,
        if (age != null) 'age': age,
        if (location != null) 'location': location,
        if (language != null) 'language': language,
        if (role != null) 'role': role,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
      body: json.encode(updates),
    );
    return _handleResponse(response);
  }

  Future<void> logout() async {
    await clearTokens();
  }

  // ==================== AI SATHI ====================
  Future<Map<String, dynamic>> aiChat(String message, String category,
      {String? language, String? healthMode}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-sathi/chat'),
      headers: _headers,
      body: json.encode({
        'message': message,
        'category': category,
        if (language != null) 'language': language,
        if (healthMode != null) 'health_mode': healthMode,
      }),
    );
    return _handleResponse(response);
  }

  /// Get AI-suggested follow-up questions based on chat context
  Future<List<String>> getSuggestedQuestions(String category,
      {List<Map<String, dynamic>>? history, String? language}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai-sathi/suggest-questions'),
        headers: _headers,
        body: json.encode({
          'category': category,
          if (history != null) 'history': history,
          if (language != null) 'language': language,
        }),
      );
      final data = await _handleResponse(response) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>?;
      return suggestions?.map((s) => s.toString()).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Analyze a health image using AI
  Future<Map<String, dynamic>> analyzeHealthImage(
    File imageFile, {
    String analysisType = 'general',
    String language = 'en',
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai-sathi/analyze-image'),
      );

      // Add headers
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      // Add the image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      // Add analysis type and language
      request.fields['type'] = analysisType;
      request.fields['language'] = language;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      // Fallback to text-based analysis description
      return {
        'analysis':
            'Image analysis is currently being processed. Based on the uploaded image, our AI is examining the visual characteristics. For accurate diagnosis, please describe your symptoms or consult a medical professional.',
        'status': 'pending',
      };
    }
  }

  Future<List<dynamic>> getAICategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai-sathi/categories'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Get AI-generated disease information
  Future<Map<String, dynamic>> getDiseaseInfo(String diseaseName) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/ai-sathi/disease-info/${Uri.encodeComponent(diseaseName)}'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getAISpecialists() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai-sathi/specialists'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Get personalized health tips based on user's medical history
  Future<Map<String, dynamic>> getPersonalizedHealthTips({
    String language = 'en',
    int count = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-sathi/personalized-health-tips'),
      headers: _headers,
      body: json.encode({
        'language': language,
        'count': count,
      }),
    );
    return _handleResponse(response);
  }

  /// Get weather and health/pandemic alerts
  Future<Map<String, dynamic>> getWeatherHealthAlerts({
    String language = 'en',
    int count = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-sathi/weather-health-alerts'),
      headers: _headers,
      body: json.encode({
        'language': language,
        'count': count,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> startLiveAICall({
    required String specialist,
    String? patientContext,
    String language = 'en-US',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-sathi/live-call/start'),
      headers: _headers,
      body: json.encode({
        'specialist': specialist,
        'patient_context': patientContext,
        'language': language,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendLiveAISpeech({
    required String sessionId,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-sathi/live-call/speech'),
      headers: _headers,
      body: json.encode({
        'session_id': sessionId,
        'text': text,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> endLiveAICall(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-sathi/live-call/end'),
      headers: _headers,
      body: json.encode({'session_id': sessionId}),
    );
    return _handleResponse(response);
  }

  // ==================== DOCTORS ====================
  Future<Map<String, dynamic>> getDoctors({
    String? specialization,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (specialization != null) 'specialization': specialization,
      if (search != null) 'search': search,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/doctors').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDoctor(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/doctors/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getSpecializations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/doctors/specializations'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  // ==================== HOSPITALS ====================
  Future<Map<String, dynamic>> getHospitals(
      {String? search, int page = 1}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null) 'search': search,
    };
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getHospital(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getHospitalMetrics(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals/$id/metrics'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getHospitalReviews(int id,
      {int page = 1, String sort = 'recent'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals/$id/reviews?page=$page&sort=$sort'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> submitHospitalReview(
      int hospitalId, Map<String, dynamic> reviewData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/hospitals/$hospitalId/reviews'),
      headers: _headers,
      body: json.encode(reviewData),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getHospitalServices(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals/$id/services'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<List<dynamic>> getHospitalGallery(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals/$id/gallery'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<List<dynamic>> getHospitalDoctors(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hospitals/$id/doctors'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> getDoctorReviews(int id, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/doctors/$id/reviews?page=$page'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> submitDoctorReview(
      int doctorId, Map<String, dynamic> reviewData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctors/$doctorId/reviews'),
      headers: _headers,
      body: json.encode(reviewData),
    );
    return _handleResponse(response);
  }

  // ==================== APPOINTMENTS ====================
  Future<Map<String, dynamic>> getAppointments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/appointments'),
      headers: _headers,
    );
    // Backend returns list directly, wrap it for screen compatibility
    final appointments = await _handleListResponse(response);
    return {'appointments': appointments};
  }

  Future<Map<String, dynamic>> bookAppointment(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getVideoCallToken(int appointmentId) async {
    // Backend uses /join POST endpoint to get room info
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/$appointmentId/join'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/$appointmentId/cancel'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> joinAppointment(int appointmentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/$appointmentId/join'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== REMINDERS ====================
  Future<Map<String, dynamic>> getReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reminders'),
      headers: _headers,
    );
    // Backend returns array directly, wrap in object for screen compatibility
    final reminders = await _handleListResponse(response);
    return {'reminders': reminders};
  }

  Future<Map<String, dynamic>> getTodayReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reminders/today'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<void> markReminderTaken(int reminderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders/$reminderId/taken'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getReminderById(int reminderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reminders/$reminderId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateReminder(
      int reminderId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reminders/$reminderId'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<void> deleteReminder(int reminderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reminders/$reminderId'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  // ==================== HEALTH ALERTS ====================
  Future<Map<String, dynamic>> getHealthAlerts(
      {double? lat, double? lng}) async {
    final queryParams = <String, String>{
      if (lat != null) 'latitude': lat.toString(),
      if (lng != null) 'longitude': lng.toString(),
    };
    final response = await http.get(
      Uri.parse('$baseUrl/health-alerts').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getHealthAlertsSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-alerts/summary'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getCriticalAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-alerts/critical'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Get COVID data with neighboring countries comparison
  Future<Map<String, dynamic>> getCovidComparison(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/disease/covid/comparison/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== WEATHER & CLIMATE ====================
  Future<Map<String, dynamic>> getWeatherData(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/weather/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getClimateData(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/climate/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCombinedHealthData(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/combined/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get historical COVID trends for charts
  Future<Map<String, dynamic>> getCovidHistorical(String country,
      {int days = 30}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/health-data/disease/covid/historical/$country?days=$days'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get vaccination coverage data
  Future<Map<String, dynamic>> getVaccinationData(String country,
      {int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/disease/vaccination/$country?days=$days'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get pollen and allergy data
  Future<Map<String, dynamic>> getPollenData(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/climate/pollen/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getEarthquakeData(String country,
      {int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health-data/earthquake/$country?days=$days'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== BLOOD BANKS ====================
  Future<Map<String, dynamic>> getBloodBanks({String? city}) async {
    final queryParams = <String, String>{
      if (city != null) 'city': city,
    };
    final response = await http.get(
      Uri.parse('$baseUrl/blood-banks').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== EMERGENCY ====================
  Future<List<dynamic>> getEmergencyServices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/emergency/services'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> getEmergencyContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/emergency/contacts'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addEmergencyContact(
      String name, String phone, String relationship) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/contacts'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'phone': phone,
        'relationship': relationship,
      }),
    );
    return _handleResponse(response);
  }

  // ==================== MEDICINES / PHARMACY ====================
  Future<Map<String, dynamic>> getMedicines(
      {String? category, String? search}) async {
    final queryParams = <String, String>{
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    };
    final response = await http.get(
      Uri.parse('$baseUrl/medicines').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getMedicineCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medicines/categories'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<List<dynamic>> getPharmacies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medicines/pharmacies'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> getPharmacy(int pharmacyId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medicines/pharmacies/$pharmacyId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== CALCULATORS ====================
  Future<Map<String, dynamic>> calculateBMI(
      double weight, double height) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calculators/bmi'),
      headers: _headers,
      body: json.encode({'weight': weight, 'height': height}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> calculateIdealWeight(
      double height, String gender) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calculators/ideal-weight'),
      headers: _headers,
      body: json.encode({'height': height, 'gender': gender}),
    );
    return _handleResponse(response);
  }

  // ==================== PREVENTION ====================
  Future<List<dynamic>> getPreventionTips() async {
    final response = await http.get(
      Uri.parse('$baseUrl/prevention/tips'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> getDailyGoals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/prevention/goals'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<void> updateGoalProgress(int goalId, int progress) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/prevention/goals/$goalId'),
      headers: _headers,
      body: json.encode({'current_value': progress}),
    );
    await _handleResponse(response);
  }

  // ==================== DISEASE SURVEILLANCE ====================

  /// Get disease outbreaks from WHO and other sources
  Future<Map<String, dynamic>> getDiseaseOutbreaks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/outbreaks'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get disease spread level for a country
  Future<Map<String, dynamic>> getDiseaseSpreadLevel(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/spread/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get regional disease alerts
  Future<Map<String, dynamic>> getRegionalAlerts(
      {String region = 'south-asia'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/regional-alerts/$region'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get active disease alerts for a country (seasonal + regional)
  Future<Map<String, dynamic>> getActiveDiseaseAlerts(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/active-alerts/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get COVID-19 data for a country
  Future<Map<String, dynamic>> getCovidData(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/covid/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get comprehensive health situation summary
  Future<Map<String, dynamic>> getHealthSituation(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/situation/$country'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get historical disease data for trends
  Future<Map<String, dynamic>> getHistoricalDiseaseData(String country,
      {int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/disease-surveillance/history/$country?days=$days'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== SIMULATIONS ====================

  /// Get all simulations
  Future<Map<String, dynamic>> getSimulations(
      {String? category, String lang = 'en'}) async {
    final queryParams = <String, String>{
      'lang': lang,
      if (category != null) 'category': category,
    };
    final response = await http.get(
      Uri.parse('$baseUrl/simulations').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get featured simulations for home screen
  Future<Map<String, dynamic>> getFeaturedSimulations(
      {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/simulations/featured?lang=$lang'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get simulation details with steps
  Future<Map<String, dynamic>> getSimulation(String slug,
      {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/simulations/$slug?lang=$lang'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Start a simulation
  Future<Map<String, dynamic>> startSimulation(int simId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/simulations/$simId/start'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Update simulation step progress
  Future<Map<String, dynamic>> updateSimulationStep(int simId, int step,
      {int? score}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/simulations/$simId/step'),
      headers: _headers,
      body: json.encode({
        'step': step,
        if (score != null) 'score': score,
      }),
    );
    return _handleResponse(response);
  }

  /// Get user's simulation progress
  Future<Map<String, dynamic>> getSimulationProgress() async {
    final response = await http.get(
      Uri.parse('$baseUrl/simulations/progress'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== MEDICAL HISTORY ====================

  /// Get user's complete medical record
  Future<Map<String, dynamic>> getMedicalRecord(
      {bool includeDetails = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history?details=$includeDetails'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Update basic medical record info
  Future<Map<String, dynamic>> updateMedicalRecord(
      Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/medical-history'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Get medical conditions
  Future<List<dynamic>> getMedicalConditions({String? status}) async {
    String url = '$baseUrl/medical-history/conditions';
    if (status != null) url += '?status=$status';
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleListResponse(response);
  }

  /// Add medical condition
  Future<Map<String, dynamic>> addMedicalCondition(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/conditions'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Update medical condition
  Future<Map<String, dynamic>> updateMedicalCondition(
      int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/medical-history/conditions/$id'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Delete medical condition
  Future<Map<String, dynamic>> deleteMedicalCondition(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medical-history/conditions/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get allergies
  Future<List<dynamic>> getMedicalAllergies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history/allergies'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Add allergy
  Future<Map<String, dynamic>> addMedicalAllergy(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/allergies'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Delete allergy
  Future<Map<String, dynamic>> deleteMedicalAllergy(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medical-history/allergies/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get medications
  Future<List<dynamic>> getMedicalMedications({bool activeOnly = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history/medications?active=$activeOnly'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Add medication
  Future<Map<String, dynamic>> addMedicalMedication(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/medications'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Update medication
  Future<Map<String, dynamic>> updateMedicalMedication(
      int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/medical-history/medications/$id'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Delete medication
  Future<Map<String, dynamic>> deleteMedicalMedication(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medical-history/medications/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get medical documents
  Future<List<dynamic>> getMedicalDocuments({String? type}) async {
    String url = '$baseUrl/medical-history/documents';
    if (type != null) url += '?type=$type';
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleListResponse(response);
  }

  /// Get single medical document
  Future<Map<String, dynamic>> getMedicalDocument(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history/documents/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Add medical document
  Future<Map<String, dynamic>> addMedicalDocument(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/documents'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Update medical document
  Future<Map<String, dynamic>> updateMedicalDocument(
      int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/medical-history/documents/$id'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Delete medical document
  Future<Map<String, dynamic>> deleteMedicalDocument(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medical-history/documents/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Add image to document
  Future<Map<String, dynamic>> addDocumentImage(
      int documentId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/documents/$documentId/images'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Get surgeries
  Future<List<dynamic>> getMedicalSurgeries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history/surgeries'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Add surgery
  Future<Map<String, dynamic>> addMedicalSurgery(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/surgeries'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Get vaccinations
  Future<List<dynamic>> getMedicalVaccinations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history/vaccinations'),
      headers: _headers,
    );
    return _handleListResponse(response);
  }

  /// Add vaccination
  Future<Map<String, dynamic>> addMedicalVaccination(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medical-history/vaccinations'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Get AI context for medical history
  Future<Map<String, dynamic>> getMedicalHistoryAIContext() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medical-history/ai-context'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============== DISEASE ENCYCLOPEDIA API ==============

  /// Search diseases
  Future<Map<String, dynamic>> searchDiseases(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/diseases/search?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get disease details
  Future<Map<String, dynamic>> getDiseaseDetails(String name,
      {String language = 'en'}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/diseases/details/${Uri.encodeComponent(name)}?lang=$language'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get disease categories
  Future<Map<String, dynamic>> getDiseaseCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/diseases/categories'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get diseases by category
  Future<Map<String, dynamic>> getDiseasesByCategory(String categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/diseases/category/$categoryId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get common diseases
  Future<Map<String, dynamic>> getCommonDiseases() async {
    final response = await http.get(
      Uri.parse('$baseUrl/diseases/common'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============== DRUG INFO API ==============

  /// Search drugs
  Future<Map<String, dynamic>> searchDrugs(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/drug-info/search?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get drug details
  Future<Map<String, dynamic>> getDrugDetails(String name,
      {String language = 'en'}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/drug-info/details/${Uri.encodeComponent(name)}?lang=$language'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get drug categories
  Future<Map<String, dynamic>> getDrugCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/drug-info/categories'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get common drugs
  Future<Map<String, dynamic>> getCommonDrugs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/drug-info/common'),
      headers: _headers,
    );
    return _handleResponse(response);
  }
}

// Global instance
final apiService = ApiService();
