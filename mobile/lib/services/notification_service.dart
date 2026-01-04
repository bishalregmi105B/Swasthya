import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// OneSignal Push Notification Service for Swasthya
class NotificationService {
  static const String _oneSignalAppId = '310873ac-026a-4117-bb9d-cfa9272b47f6';
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  bool _isInitialized = false;
  String? _playerId;
  
  /// Get the OneSignal Player ID (device token)
  String? get playerId => _playerId;
  
  /// Initialize OneSignal SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Remove deprecated setLogLevel if needed
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Initialize OneSignal
      OneSignal.initialize(_oneSignalAppId);
      
      // Request push notification permission
      await OneSignal.Notifications.requestPermission(true);
      
      // Get the player ID
      _playerId = OneSignal.User.pushSubscription.id;
      
      // Listen for player ID changes
      OneSignal.User.pushSubscription.addObserver((state) {
        _playerId = state.current.id;
        _savePlayerIdLocally();
        print('OneSignal Player ID: $_playerId');
      });
      
      // Handle notification opened
      OneSignal.Notifications.addClickListener((event) {
        _handleNotificationOpened(event);
      });
      
      // Handle notification received in foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        _handleForegroundNotification(event);
      });
      
      _isInitialized = true;
      print('OneSignal initialized successfully');
      
      // Save player ID if available
      if (_playerId != null) {
        _savePlayerIdLocally();
      }
      
    } catch (e) {
      print('Error initializing OneSignal: $e');
    }
  }
  
  /// Set external user ID (link with backend user)
  Future<void> setExternalUserId(String userId) async {
    try {
      OneSignal.login(userId);
      print('OneSignal: External user ID set to $userId');
    } catch (e) {
      print('Error setting external user ID: $e');
    }
  }
  
  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    try {
      OneSignal.logout();
      print('OneSignal: External user ID removed');
    } catch (e) {
      print('Error removing external user ID: $e');
    }
  }
  
  /// Set user tags for segmentation
  Future<void> setUserTags(Map<String, dynamic> tags) async {
    try {
      // Convert all values to strings
      final stringTags = tags.map((k, v) => MapEntry(k, v.toString()));
      OneSignal.User.addTags(stringTags);
      print('OneSignal: Tags set: $stringTags');
    } catch (e) {
      print('Error setting user tags: $e');
    }
  }
  
  /// Remove user tags
  Future<void> removeUserTags(List<String> tagKeys) async {
    try {
      OneSignal.User.removeTags(tagKeys);
      print('OneSignal: Tags removed: $tagKeys');
    } catch (e) {
      print('Error removing user tags: $e');
    }
  }
  
  /// Save player ID locally for backend sync
  void _savePlayerIdLocally() {
    if (_playerId != null) {
      final box = Hive.box('settings');
      box.put('onesignal_player_id', _playerId);
    }
  }
  
  /// Get locally saved player ID
  String? getSavedPlayerId() {
    final box = Hive.box('settings');
    return box.get('onesignal_player_id');
  }
  
  /// Handle notification opened (user tapped)
  void _handleNotificationOpened(OSNotificationClickEvent event) {
    print('Notification opened: ${event.notification.title}');
    
    final data = event.notification.additionalData;
    if (data != null) {
      // Handle different notification types
      final type = data['type'] as String?;
      final targetId = data['target_id'] as String?;
      
      switch (type) {
        case 'appointment':
          // Navigate to appointment
          print('Navigate to appointment: $targetId');
          break;
        case 'reminder':
          // Navigate to reminders
          print('Navigate to reminder: $targetId');
          break;
        case 'health_alert':
          // Navigate to health alerts
          print('Navigate to health alert: $targetId');
          break;
        case 'chat':
          // Navigate to chat
          print('Navigate to chat: $targetId');
          break;
        default:
          print('Unknown notification type: $type');
      }
    }
  }
  
  /// Handle foreground notification
  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    print('Foreground notification: ${event.notification.title}');
    
    // Display the notification (default behavior)
    event.notification.display();
  }
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return OneSignal.Notifications.permission;
  }
  
  /// Request notification permission
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
}

/// Global notification service instance
final notificationService = NotificationService();
