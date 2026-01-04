import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Medicine Alarm Service for scheduling local notifications
/// Provides alarm-style reminders for medicine intake
class MedicineAlarmService {
  static final MedicineAlarmService _instance =
      MedicineAlarmService._internal();
  factory MedicineAlarmService() => _instance;
  MedicineAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Notification channel for medicine alarms (Android)
  static const String _channelId = 'medicine_alarms';
  static const String _channelName = 'Medicine Reminders';
  static const String _channelDescription =
      'Alarm notifications for medicine reminders';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Set local timezone based on device's timezone
    final String timeZoneName = await _getLocalTimezoneName();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint('[MedicineAlarm] Timezone set to: $timeZoneName');

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _isInitialized = true;
    debugPrint('[MedicineAlarm] Service initialized');

    // Run diagnostics
    await runDiagnostics();
  }

  /// Run diagnostic checks and log results
  Future<Map<String, dynamic>> runDiagnostics() async {
    debugPrint('[MedicineAlarm] ===== DIAGNOSTICS =====');

    final results = <String, dynamic>{
      'notificationsEnabled': false,
      'exactAlarmsAllowed': false,
      'pendingCount': 0,
      'batteryOptimized': true, // Assume optimized (bad) unless we can check
    };

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Check notification permission
      final notifEnabled =
          await androidPlugin?.areNotificationsEnabled() ?? false;
      results['notificationsEnabled'] = notifEnabled;
      debugPrint('[MedicineAlarm] Notifications enabled: $notifEnabled');

      // Check exact alarm permission
      final canSchedule =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      results['exactAlarmsAllowed'] = canSchedule;
      debugPrint('[MedicineAlarm] Can schedule exact alarms: $canSchedule');

      // Check pending notifications
      final pending = await _notifications.pendingNotificationRequests();
      results['pendingCount'] = pending.length;
      debugPrint('[MedicineAlarm] Pending notifications: ${pending.length}');
      for (var p in pending.take(5)) {
        debugPrint('[MedicineAlarm]   - ID: ${p.id}, Title: ${p.title}');
      }
    }

    debugPrint('[MedicineAlarm] Timezone: ${tz.local.name}');
    debugPrint('[MedicineAlarm] Current time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('[MedicineAlarm] ===== END DIAGNOSTICS =====');

    return results;
  }

  /// Request battery optimization exemption (crucial for MIUI, Samsung, Huawei)
  /// Opens app settings where user can disable battery optimization
  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;

    try {
      // Use MethodChannel to open battery optimization settings
      const channel = MethodChannel('com.example.swasthya/battery');
      await channel.invokeMethod('requestIgnoreBatteryOptimization');
      debugPrint('[MedicineAlarm] Requested battery optimization exemption');
    } catch (e) {
      debugPrint(
          '[MedicineAlarm] Battery exemption error: $e - trying app settings');
      // Fallback: try to open app settings
      try {
        const channel = MethodChannel('com.example.swasthya/settings');
        await channel.invokeMethod('openAppSettings');
      } catch (e2) {
        debugPrint('[MedicineAlarm] Could not open settings: $e2');
      }
    }
  }

  /// Get instructions for enabling alarms on specific manufacturers
  String getBatteryOptimizationInstructions() {
    return '''
⚠️ Your device may prevent medicine alarms from working.

To fix this:
1. Go to Settings → Apps → Swasthya
2. Battery → "No restrictions" or "Unrestricted"
3. Enable "Autostart" (if available)

For Xiaomi/MIUI:
→ Settings → Apps → Manage apps → Swasthya
→ Autostart: ON
→ Battery saver: No restrictions
→ Other permissions → Show on Lock screen: ON

For Samsung:
→ Settings → Apps → Swasthya → Battery
→ "Unrestricted" or "Allow background activity"

For Huawei:
→ Settings → Apps → Swasthya → Battery
→ Launch: Manage manually
→ Enable all toggles
''';
  }

  /// Get local timezone name from device
  Future<String> _getLocalTimezoneName() async {
    try {
      // Get the device's timezone offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Map common offsets to timezone names
      // Nepal is UTC+5:45
      if (offset.inMinutes == 345) {
        return 'Asia/Kathmandu';
      } else if (offset.inMinutes == 330) {
        return 'Asia/Kolkata'; // India
      } else if (offset.inHours == 8) {
        return 'Asia/Singapore';
      } else if (offset.inHours == 9) {
        return 'Asia/Tokyo';
      } else if (offset.inHours == 0) {
        return 'UTC';
      } else if (offset.inHours == -5) {
        return 'America/New_York';
      } else if (offset.inHours == -8) {
        return 'America/Los_Angeles';
      }

      // Default fallback - use UTC offset based location
      return 'Asia/Kathmandu'; // Default for Nepal app
    } catch (e) {
      debugPrint('[MedicineAlarm] Timezone detection error: $e');
      return 'Asia/Kathmandu';
    }
  }

  /// Create notification channel for Android with alarm-like sound
  Future<void> _createNotificationChannel() async {
    final channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      // Use default system alarm sound
      sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert'),
      // Long vibration pattern for alarm effect
      vibrationPattern:
          Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('[MedicineAlarm] Alarm notification channel created');
  }

  /// Schedule a medicine reminder alarm
  Future<void> scheduleReminder({
    required int reminderId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    String? instructions,
    bool isDaily = true,
  }) async {
    if (!_isInitialized) await initialize();

    // Create notification details with alarm-like behavior
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Medicine Reminder',
      fullScreenIntent: true, // Wake up device
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      // Use system alarm sound
      sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert'),
      playSound: true,
      enableVibration: true,
      vibrationPattern:
          Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
      // Keep ringing until user interacts
      ongoing: true,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      actions: const [
        AndroidNotificationAction(
          'take',
          'Take Now',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze 10 min',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate next occurrence
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Check how much time has passed since the scheduled time
    final timeDifference = now.difference(scheduledDate);

    // If the scheduled time is in the future, use it
    // If it just passed (within 2 minutes), schedule for 10 seconds from now
    // If it passed more than 2 minutes ago, schedule for tomorrow
    if (scheduledDate.isAfter(now)) {
      // Time is in the future - use it as is
      debugPrint('[MedicineAlarm] Time is in future, scheduling for today');
    } else if (timeDifference.inMinutes < 2) {
      // Time just passed (within 2 minutes) - schedule for 10 seconds from now
      scheduledDate = now.add(const Duration(seconds: 10));
      debugPrint(
          '[MedicineAlarm] Time just passed, scheduling for 10 seconds from now');
    } else {
      // Time passed more than 2 minutes ago - schedule for tomorrow
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint(
          '[MedicineAlarm] Time passed >2 min ago, scheduling for tomorrow');
    }

    debugPrint('[MedicineAlarm] NOW: $now');
    debugPrint('[MedicineAlarm] SCHEDULED FOR: $scheduledDate');
    debugPrint(
        '[MedicineAlarm] Time until alarm: ${scheduledDate.difference(now)}');

    // Schedule the notification
    // Use alarmClock mode - this shows in device's alarm list and is harder for OEMs to block
    await _notifications.zonedSchedule(
      reminderId,
      '💊 Time for $medicineName',
      dosage + (instructions != null ? '\n$instructions' : ''),
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: isDaily ? DateTimeComponents.time : null,
      payload: 'reminder:$reminderId',
    );

    debugPrint(
        '[MedicineAlarm] ✅ Scheduled: $medicineName at ${scheduledDate.hour}:${scheduledDate.minute} (ID: $reminderId)');
  }

  /// Schedule multiple reminders for a medicine (multiple times per day)
  Future<void> scheduleMultipleReminders({
    required int baseReminderId,
    required String medicineName,
    required String dosage,
    required List<String> times,
    String? instructions,
  }) async {
    debugPrint(
        '[MedicineAlarm] scheduleMultipleReminders called with times: $times');

    for (int i = 0; i < times.length; i++) {
      debugPrint('[MedicineAlarm] Parsing time[${i}]: "${times[i]}"');
      final timeParts = times[i].split(':');
      final hour = int.tryParse(timeParts[0]) ?? 8;
      final minute =
          int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

      debugPrint('[MedicineAlarm] Parsed hour=$hour, minute=$minute');

      // Use unique ID for each time slot
      final notificationId = baseReminderId * 100 + i;

      await scheduleReminder(
        reminderId: notificationId,
        medicineName: medicineName,
        dosage: dosage,
        hour: hour,
        minute: minute,
        instructions: instructions,
      );
    }
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(int reminderId) async {
    await _notifications.cancel(reminderId);
    debugPrint('[MedicineAlarm] Cancelled reminder ID: $reminderId');
  }

  /// Cancel all reminders for a medicine (multiple time slots)
  Future<void> cancelMultipleReminders(
      int baseReminderId, int timesCount) async {
    for (int i = 0; i < timesCount; i++) {
      final notificationId = baseReminderId * 100 + i;
      await _notifications.cancel(notificationId);
    }
    debugPrint(
        '[MedicineAlarm] Cancelled $timesCount reminders for base ID: $baseReminderId');
  }

  /// Cancel all medicine reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    debugPrint('[MedicineAlarm] All reminders cancelled');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Request notification permission
      final notifResult = await androidPlugin?.requestNotificationsPermission();
      debugPrint('[MedicineAlarm] Notification permission: $notifResult');

      // Check and request exact alarm permission (Android 12+)
      final canSchedule = await androidPlugin?.canScheduleExactNotifications();
      debugPrint('[MedicineAlarm] Can schedule exact alarms: $canSchedule');

      if (canSchedule == false) {
        // Request exact alarm permission - opens settings
        await androidPlugin?.requestExactAlarmsPermission();
        debugPrint('[MedicineAlarm] Requested exact alarm permission');
      }

      return notifResult ?? false;
    }

    return true;
  }

  /// Check if exact alarms can be scheduled (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      return result ?? true;
    }
    return true;
  }

  /// Request exact alarm permission (Android 12+)
  /// Opens system settings for the user to enable
  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final canSchedule = await canScheduleExactAlarms();
      if (!canSchedule) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
        debugPrint('[MedicineAlarm] Opening exact alarm settings');
      } else {
        debugPrint('[MedicineAlarm] Exact alarm permission already granted');
      }
    }
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '💊 Test Medicine Reminder',
      'This is a test notification. Your alarms are working!',
      details,
    );
    debugPrint('[MedicineAlarm] Immediate notification shown');
  }

  /// Schedule a test reminder 10 seconds from now
  Future<bool> scheduleTestReminder() async {
    try {
      if (!_isInitialized) await initialize();

      // Check exact alarm permission first (Android 12+)
      if (Platform.isAndroid) {
        final canSchedule = await canScheduleExactAlarms();
        debugPrint(
            '[MedicineAlarm] TEST: Can schedule exact alarms: $canSchedule');
        if (!canSchedule) {
          debugPrint('[MedicineAlarm] TEST: Exact alarm permission required!');
          await requestExactAlarmPermission();
          return false;
        }
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
        sound: const UriAndroidNotificationSound(
            'content://settings/system/alarm_alert'),
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

      debugPrint(
          '[MedicineAlarm] TEST: Scheduling for 10 seconds from now: $scheduledTime');

      await _notifications.zonedSchedule(
        99999, // Test ID
        '💊 Test Scheduled Reminder',
        'This notification was scheduled 10 seconds ago!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'test',
      );

      debugPrint(
          '[MedicineAlarm] TEST: Reminder scheduled! Wait 10 seconds...');

      // Verify it was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final testPending = pending.where((p) => p.id == 99999);
      debugPrint(
          '[MedicineAlarm] TEST: Found ${testPending.length} test notification(s) pending');

      return true;
    } catch (e) {
      debugPrint('[MedicineAlarm] TEST ERROR: Failed to schedule - $e');
      return false;
    }
  }

  /// Handle notification tap in foreground
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[MedicineAlarm] Notification tapped: ${response.payload}');

    if (response.actionId == 'take') {
      // TODO: Mark medicine as taken
      debugPrint('[MedicineAlarm] User tapped "Take Now"');
    } else if (response.actionId == 'snooze') {
      // Snooze for 10 minutes
      snoozeReminder(response.id ?? 0, minutes: 10);
    }
  }

  /// Snooze a reminder for specified minutes
  Future<void> snoozeReminder(int reminderId, {int minutes = 10}) async {
    final snoozeTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      reminderId + 10000, // Different ID for snooze
      '💊 Snoozed Reminder',
      'Time to take your medicine (snoozed)',
      snoozeTime,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );

    debugPrint('[MedicineAlarm] Snoozed for $minutes minutes');
  }
}

/// Background notification tap handler (must be top-level function)
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  debugPrint(
      '[MedicineAlarm] Background notification tapped: ${response.payload}');
}

/// Global instance
final medicineAlarmService = MedicineAlarmService();
