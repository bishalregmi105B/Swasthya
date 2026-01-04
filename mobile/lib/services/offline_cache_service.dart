import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class OfflineCacheService {
  static const String _doctorsBox = 'doctors_cache';
  static const String _remindersBox = 'reminders_cache';
  static const String _alertsBox = 'alerts_cache';
  static const String _emergencyBox = 'emergency_cache';
  static const String _pharmaciesBox = 'pharmacies_cache';
  static const String _medicalHistoryBox = 'medical_history_cache';
  static const String _simulationsBox = 'simulations_cache';
  static const String _hospitalsBox = 'hospitals_cache';
  static const String _bloodBanksBox = 'blood_banks_cache';
  static const String _userProfileBox = 'user_profile_cache';
  static const String _weatherBox = 'weather_cache';
  static const String _nearbyBox = 'nearby_cache';
  static const String _appointmentsBox = 'appointments_cache';
  static const String _diseasesBox = 'diseases_cache';
  static const String _drugsBox = 'drugs_cache';

  static Future<void> init() async {
    await Hive.openBox(_doctorsBox);
    await Hive.openBox(_remindersBox);
    await Hive.openBox(_alertsBox);
    await Hive.openBox(_emergencyBox);
    await Hive.openBox(_pharmaciesBox);
    await Hive.openBox(_medicalHistoryBox);
    await Hive.openBox(_simulationsBox);
    await Hive.openBox(_hospitalsBox);
    await Hive.openBox(_bloodBanksBox);
    await Hive.openBox(_userProfileBox);
    await Hive.openBox(_weatherBox);
    await Hive.openBox(_nearbyBox);
    await Hive.openBox(_appointmentsBox);
    await Hive.openBox(_diseasesBox);
    await Hive.openBox(_drugsBox);
    await Hive.openBox('cache');
  }

  // ==================== DOCTORS ====================
  static Future<void> cacheDoctors(List<Map<String, dynamic>> doctors) async {
    final box = Hive.box(_doctorsBox);
    await box.put('list', json.encode(doctors));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedDoctors() {
    final box = Hive.box(_doctorsBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static bool isDoctorsCacheValid() {
    final box = Hive.box(_doctorsBox);
    final timestamp = box.get('timestamp');
    if (timestamp == null) return false;
    final cached = DateTime.parse(timestamp);
    return DateTime.now().difference(cached).inHours < 24;
  }

  // ==================== REMINDERS ====================
  static Future<void> cacheReminders(
      List<Map<String, dynamic>> reminders) async {
    final box = Hive.box(_remindersBox);
    await box.put('list', json.encode(reminders));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedReminders() {
    final box = Hive.box(_remindersBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== HEALTH ALERTS ====================
  static Future<void> cacheAlerts(List<Map<String, dynamic>> alerts) async {
    final box = Hive.box(_alertsBox);
    await box.put('list', json.encode(alerts));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedAlerts() {
    final box = Hive.box(_alertsBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== EMERGENCY ====================
  static Future<void> cacheEmergencyContacts(
      List<Map<String, dynamic>> contacts) async {
    final box = Hive.box(_emergencyBox);
    await box.put('contacts', json.encode(contacts));
  }

  static List<Map<String, dynamic>>? getCachedEmergencyContacts() {
    final box = Hive.box(_emergencyBox);
    final data = box.get('contacts');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheEmergencyServices(
      List<Map<String, dynamic>> services) async {
    final box = Hive.box(_emergencyBox);
    await box.put('services', json.encode(services));
  }

  static List<Map<String, dynamic>>? getCachedEmergencyServices() {
    final box = Hive.box(_emergencyBox);
    final data = box.get('services');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== PHARMACIES ====================
  static Future<void> cachePharmacies(
      List<Map<String, dynamic>> pharmacies) async {
    final box = Hive.box(_pharmaciesBox);
    await box.put('list', json.encode(pharmacies));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedPharmacies() {
    final box = Hive.box(_pharmaciesBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== MEDICAL HISTORY ====================
  static Future<void> cacheMedicalRecord(Map<String, dynamic> record) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('record', json.encode(record));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static Map<String, dynamic>? getCachedMedicalRecord() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('record');
    if (data == null) return null;
    return Map<String, dynamic>.from(json.decode(data));
  }

  static Future<void> cacheMedicalConditions(
      List<Map<String, dynamic>> conditions) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('conditions', json.encode(conditions));
  }

  static List<Map<String, dynamic>>? getCachedMedicalConditions() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('conditions');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheMedicalAllergies(
      List<Map<String, dynamic>> allergies) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('allergies', json.encode(allergies));
  }

  static List<Map<String, dynamic>>? getCachedMedicalAllergies() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('allergies');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheMedicalMedications(
      List<Map<String, dynamic>> medications) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('medications', json.encode(medications));
  }

  static List<Map<String, dynamic>>? getCachedMedicalMedications() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('medications');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheMedicalDocuments(
      List<Map<String, dynamic>> documents) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('documents', json.encode(documents));
  }

  static List<Map<String, dynamic>>? getCachedMedicalDocuments() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('documents');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheMedicalSurgeries(
      List<Map<String, dynamic>> surgeries) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('surgeries', json.encode(surgeries));
  }

  static List<Map<String, dynamic>>? getCachedMedicalSurgeries() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('surgeries');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheMedicalVaccinations(
      List<Map<String, dynamic>> vaccinations) async {
    final box = Hive.box(_medicalHistoryBox);
    await box.put('vaccinations', json.encode(vaccinations));
  }

  static List<Map<String, dynamic>>? getCachedMedicalVaccinations() {
    final box = Hive.box(_medicalHistoryBox);
    final data = box.get('vaccinations');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== SIMULATIONS ====================
  static Future<void> cacheSimulations(
      List<Map<String, dynamic>> simulations) async {
    final box = Hive.box(_simulationsBox);
    await box.put('list', json.encode(simulations));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedSimulations() {
    final box = Hive.box(_simulationsBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== HOSPITALS ====================
  static Future<void> cacheHospitals(
      List<Map<String, dynamic>> hospitals) async {
    final box = Hive.box(_hospitalsBox);
    await box.put('list', json.encode(hospitals));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedHospitals() {
    final box = Hive.box(_hospitalsBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== BLOOD BANKS ====================
  static Future<void> cacheBloodBanks(
      List<Map<String, dynamic>> bloodBanks) async {
    final box = Hive.box(_bloodBanksBox);
    await box.put('list', json.encode(bloodBanks));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedBloodBanks() {
    final box = Hive.box(_bloodBanksBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== USER PROFILE ====================
  static Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(_userProfileBox);
    await box.put('profile', json.encode(profile));
  }

  static Map<String, dynamic>? getCachedUserProfile() {
    final box = Hive.box(_userProfileBox);
    final data = box.get('profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(json.decode(data));
  }

  // ==================== WEATHER ====================
  static Future<void> cacheWeather(Map<String, dynamic> weather) async {
    final box = Hive.box(_weatherBox);
    await box.put('data', json.encode(weather));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static Map<String, dynamic>? getCachedWeather() {
    final box = Hive.box(_weatherBox);
    final data = box.get('data');
    if (data == null) return null;
    return Map<String, dynamic>.from(json.decode(data));
  }

  static bool isWeatherCacheValid({int maxMinutes = 30}) {
    final box = Hive.box(_weatherBox);
    final timestamp = box.get('timestamp');
    if (timestamp == null) return false;
    final cached = DateTime.parse(timestamp);
    return DateTime.now().difference(cached).inMinutes < maxMinutes;
  }

  // ==================== NEARBY FACILITIES ====================
  static Future<void> cacheNearby(
      String type, List<Map<String, dynamic>> facilities) async {
    final box = Hive.box(_nearbyBox);
    await box.put(type, json.encode(facilities));
    await box.put('${type}_timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedNearby(String type) {
    final box = Hive.box(_nearbyBox);
    final data = box.get(type);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== APPOINTMENTS ====================
  static Future<void> cacheAppointments(
      List<Map<String, dynamic>> appointments) async {
    final box = Hive.box(_appointmentsBox);
    await box.put('list', json.encode(appointments));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedAppointments() {
    final box = Hive.box(_appointmentsBox);
    final data = box.get('list');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // ==================== DISEASES (Encyclopedia) ====================
  static Future<void> cacheDiseaseSearch(
      String query, List<Map<String, dynamic>> results) async {
    final box = Hive.box(_diseasesBox);
    await box.put('search_$query', json.encode(results));
  }

  static List<Map<String, dynamic>>? getCachedDiseaseSearch(String query) {
    final box = Hive.box(_diseasesBox);
    final data = box.get('search_$query');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheCommonDiseases(
      List<Map<String, dynamic>> diseases) async {
    final box = Hive.box(_diseasesBox);
    await box.put('common', json.encode(diseases));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedCommonDiseases() {
    final box = Hive.box(_diseasesBox);
    final data = box.get('common');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheDiseaseDetail(
      String name, Map<String, dynamic> detail) async {
    final box = Hive.box(_diseasesBox);
    await box.put('detail_$name', json.encode(detail));
  }

  static Map<String, dynamic>? getCachedDiseaseDetail(String name) {
    final box = Hive.box(_diseasesBox);
    final data = box.get('detail_$name');
    if (data == null) return null;
    return Map<String, dynamic>.from(json.decode(data));
  }

  // ==================== DRUGS (Info) ====================
  static Future<void> cacheDrugSearch(
      String query, List<Map<String, dynamic>> results) async {
    final box = Hive.box(_drugsBox);
    await box.put('search_$query', json.encode(results));
  }

  static List<Map<String, dynamic>>? getCachedDrugSearch(String query) {
    final box = Hive.box(_drugsBox);
    final data = box.get('search_$query');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheCommonDrugs(List<Map<String, dynamic>> drugs) async {
    final box = Hive.box(_drugsBox);
    await box.put('common', json.encode(drugs));
    await box.put('timestamp', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>>? getCachedCommonDrugs() {
    final box = Hive.box(_drugsBox);
    final data = box.get('common');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
        (json.decode(data) as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> cacheDrugDetail(
      String name, Map<String, dynamic> detail) async {
    final box = Hive.box(_drugsBox);
    await box.put('detail_$name', json.encode(detail));
  }

  static Map<String, dynamic>? getCachedDrugDetail(String name) {
    final box = Hive.box(_drugsBox);
    final data = box.get('detail_$name');
    if (data == null) return null;
    return Map<String, dynamic>.from(json.decode(data));
  }

  // ==================== GENERIC CACHE ====================
  static Future<void> cacheData(String key, dynamic data) async {
    final box = Hive.box('cache');
    await box.put(key, json.encode(data));
    await box.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  static dynamic getCachedData(String key) {
    final box = Hive.box('cache');
    final data = box.get(key);
    if (data == null) return null;
    return json.decode(data);
  }

  static bool isCacheValid(String key, {int maxHours = 24}) {
    final box = Hive.box('cache');
    final timestamp = box.get('${key}_timestamp');
    if (timestamp == null) return false;
    final cached = DateTime.parse(timestamp);
    return DateTime.now().difference(cached).inHours < maxHours;
  }

  // ==================== CLEAR CACHE ====================
  static Future<void> clearAll() async {
    await Hive.box(_doctorsBox).clear();
    await Hive.box(_remindersBox).clear();
    await Hive.box(_alertsBox).clear();
    await Hive.box(_emergencyBox).clear();
    await Hive.box(_pharmaciesBox).clear();
    await Hive.box(_medicalHistoryBox).clear();
    await Hive.box(_simulationsBox).clear();
    await Hive.box(_hospitalsBox).clear();
    await Hive.box(_bloodBanksBox).clear();
    await Hive.box(_userProfileBox).clear();
    await Hive.box(_weatherBox).clear();
    await Hive.box(_nearbyBox).clear();
    await Hive.box(_appointmentsBox).clear();
    await Hive.box(_diseasesBox).clear();
    await Hive.box(_drugsBox).clear();
    await Hive.box('cache').clear();
  }

  // ==================== PENDING ACTIONS ====================
  static Future<void> addPendingAction(
      String type, Map<String, dynamic> data) async {
    final box = Hive.box('cache');
    List<dynamic> pending = box.get('pending_actions', defaultValue: []);
    pending.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await box.put('pending_actions', pending);
  }

  static List<Map<String, dynamic>> getPendingActions() {
    final box = Hive.box('cache');
    final pending = box.get('pending_actions', defaultValue: []);
    return List<Map<String, dynamic>>.from(
        (pending as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> clearPendingActions() async {
    final box = Hive.box('cache');
    await box.delete('pending_actions');
  }

  /// Sync pending actions when back online
  static Future<int> syncPendingActions(
      Future<bool> Function(String type, Map<String, dynamic> data)
          syncFunction) async {
    final pending = getPendingActions();
    int synced = 0;

    for (var action in pending) {
      try {
        final success = await syncFunction(action['type'], action['data']);
        if (success) synced++;
      } catch (e) {
        // Keep for next sync attempt
      }
    }

    if (synced == pending.length) {
      await clearPendingActions();
    }

    return synced;
  }
}
