import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _onboardedKey = 'is_onboarded';

  final Box _settingsBox = Hive.box('settings');
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  User? _user;
  String? _accessToken;
  bool _isLoading = false;
  bool _isOnboarded = false;

  AuthProvider() {
    _loadAuthState();
  }

  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null;
  bool get isOnboarded => _isOnboarded;

  void _loadAuthState() {
    _accessToken = _settingsBox.get(_tokenKey);
    _isOnboarded = _settingsBox.get(_onboardedKey, defaultValue: false);

    final userData = _settingsBox.get(_userKey);
    if (userData != null) {
      _user = User.fromJson(Map<String, dynamic>.from(userData));
    }
  }

  Future<void> setOnboarded() async {
    _isOnboarded = true;
    await _settingsBox.put(_onboardedKey, true);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      _accessToken = response['access_token'];
      _user = User.fromJson(response['user']);

      await _settingsBox.put(_tokenKey, _accessToken);
      await _settingsBox.put(_refreshTokenKey, response['refresh_token']);
      await _settingsBox.put(_userKey, response['user']);

      // Link user ID with OneSignal for targeted push notifications
      if (_user?.id != null) {
        await notificationService.setExternalUserId(_user!.id.toString());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName, {
    int? age,
    String? location,
    String? language,
    String? role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email,
        password,
        fullName,
        age: age,
        location: location,
        language: language,
        role: role,
      );

      _accessToken = response['access_token'];
      _user = User.fromJson(response['user']);

      await _settingsBox.put(_tokenKey, _accessToken);
      await _settingsBox.put(_refreshTokenKey, response['refresh_token']);
      await _settingsBox.put(_userKey, response['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google using Firebase Authentication
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out first to ensure account selection
      await _googleSignIn.signOut();

      // Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get Google auth credentials
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Send user info directly to backend (Firebase already verified)
      final response = await _apiService.googleSignIn(
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? '',
        googleId: firebaseUser.uid,
        photoUrl: firebaseUser.photoURL ?? '',
      );

      _accessToken = response['access_token'];
      _user = User.fromJson(response['user']);

      await _settingsBox.put(_tokenKey, _accessToken);
      await _settingsBox.put(_refreshTokenKey, response['refresh_token']);
      await _settingsBox.put(_userKey, response['user']);

      // Link user ID with OneSignal
      if (_user?.id != null) {
        await notificationService.setExternalUserId(_user!.id.toString());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;

    await _settingsBox.delete(_tokenKey);
    await _settingsBox.delete(_refreshTokenKey);
    await _settingsBox.delete(_userKey);

    // Sign out from Google and Firebase
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (_) {}

    // Remove user from OneSignal
    await notificationService.removeExternalUserId();

    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    _user = user;
    await _settingsBox.put(_userKey, user.toJson());
    notifyListeners();
  }
}
