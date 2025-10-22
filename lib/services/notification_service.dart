import 'dart:io'; // ✅ ADD THIS IMPORT
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Channel configuration
  static const String channelId = 'quiz_reminders';
  static const String channelName = 'Quiz Reminders';
  static const String channelDescription = 'Silent quiz reminder notifications';

  // Notification IDs for different times
  static const int morningNotificationId = 1001;
  static const int afternoonNotificationId = 1002;
  static const int eveningNotificationId = 1003;
  
  // Daily Challenge specific notification IDs
  static const int dailyChallengeNotificationId = 3001;

  /// Initialize the notification service (Android-only, device local time)
  Future<void> initialize() async {
    try {
      // Load timezone database - tz.local will reflect device time zone
      tz.initializeTimeZones();

      debugPrint('📱 Device timezone: ${DateTime.now().timeZoneName}');
      debugPrint('📱 TZ local time: ${tz.TZDateTime.now(tz.local)}');

      // Android-only initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels
      await createNotificationChannels();

      // Request notification permissions for Android 13+
      await requestNotificationPermissions();

      final localTime = tz.TZDateTime.now(tz.local);
      debugPrint('📱 Notification service initialized (Android-only)');
      debugPrint('📱 Local timezone: ${localTime.timeZoneName}');
      debugPrint('📱 Current local time: ${localTime.toString()}');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> requestNotificationPermissions() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    try {
      final bool? granted = await androidPlugin.requestNotificationsPermission();
      if (granted == true) {
        debugPrint('📱 Notification permissions granted');
      } else {
        debugPrint('⚠️ Notification permissions denied');
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }

  /// Create notification channels for Android
  Future<void> createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Quiz reminder channel (silent)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.low, // Silent notifications
        playSound: false,
        enableVibration: false,
        showBadge: true,
        enableLights: false,
      ),
    );

    debugPrint('📱 Notification channels created successfully');
  }

  /// Handle notification tap when app is running
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Add navigation logic here if needed
    // Example: Navigate to quiz screen
  }

  /// Request notification permission for Android 13+
  Future<void> _requestAndroidPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? granted = await androidPlugin
          ?.requestNotificationsPermission();
      debugPrint('📱 Notification permission granted: $granted');
    } catch (e) {
      debugPrint('❌ Error requesting Android notification permission: $e');
    }
  }

  /// Request exact alarm permission for Android 12+
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestExactAlarmsPermission();
      debugPrint('📱 Exact alarm permission requested');
    } catch (e) {
      debugPrint('❌ Error requesting exact alarm permission: $e');
    }
  }

  /// Request permissions when needed (called explicitly by user action)
  Future<bool> requestPermissions() async {
    try {
      await _requestAndroidPermission();
      await requestExactAlarmPermission();
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Enable daily challenge notifications at 8AM, 2PM, and 5PM
  Future<void> enableDailyChallengeNotifications() async {
    try {
      // Request permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Cannot enable notifications without permissions');
        return;
      }
      
      // Cancel existing daily challenge notifications
      await cancelDailyChallengeNotifications();

      // Schedule morning notification (8:00 AM local time)
      await scheduleDailyAt(
        id: morningNotificationId,
        hour: 8,
        minute: 0,
        title: '🌅 Daily Challenge Available!',
        body: 'Start your day with today\'s quiz challenge!',
      );

      // Schedule afternoon notification (2:00 PM local time)
      await scheduleDailyAt(
        id: afternoonNotificationId,
        hour: 14,
        minute: 0,
        title: '☀️ Don\'t Miss Today\'s Challenge!',
        body: 'Take a break and play today\'s daily challenge.',
      );

      // Schedule evening notification (5:00 PM local time)
      await scheduleDailyAt(
        id: eveningNotificationId,
        hour: 17,
        minute: 0,
        title: '🌆 Last Chance for Today\'s Challenge!',
        body: 'Complete today\'s daily challenge before it expires.',
      );

      debugPrint('📅 Daily challenge notifications scheduled at 8AM, 2PM, and 5PM');

      // Show current pending notifications for verification
      final pending = await getPendingNotifications();
      debugPrint('📅 Total pending notifications: ${pending.length}');
      for (final notification in pending) {
        debugPrint('   - ID ${notification.id}: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Error enabling daily challenge notifications: $e');
    }
  }

  /// Enable automatic silent notifications at device local times
  Future<void> enableSilentNotifications() async {
    try {
      // Request permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Cannot enable notifications without permissions');
        return;
      }
      // Cancel all existing notifications first
      await _notifications.cancelAll();
      debugPrint('📱 Cancelled all existing notifications');

      // Schedule morning notification (8:00 AM local time)
      await scheduleDailyAt(
        id: morningNotificationId,
        hour: 8,
        minute: 0,
        title: '🌅 Good Morning!',
        body: 'Start your day with Quiz Master! Test your knowledge.',
      );

      // Schedule afternoon notification (2:00 PM local time)
      await scheduleDailyAt(
        id: afternoonNotificationId,
        hour: 14,
        minute: 0,
        title: '☀️ Afternoon Brain Break!',
        body: 'Time for a quick quiz! Challenge yourself.',
      );

      // Schedule evening notification (5:00 PM local time)
      await scheduleDailyAt(
        id: eveningNotificationId,
        hour: 17,
        minute: 0,
        title: '🌆 Evening Quiz Time!',
        body: 'End your day with knowledge! Play some quizzes.',
      );

      debugPrint('📅 Daily notifications scheduled in device local time');

      // Show current pending notifications for verification
      final pending = await getPendingNotifications();
      debugPrint('📅 Total pending notifications: ${pending.length}');
      for (final notification in pending) {
        debugPrint('   - ID ${notification.id}: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Error enabling silent notifications: $e');
    }
  }

  /// Schedule a silent daily notification at specific local time
  Future<void> scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final scheduledTime = _nextInstanceLocal(hour, minute);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        _getSilentNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeats daily at local time
      );

      debugPrint('⏰ Scheduled notification $id');
      debugPrint('   Title: $title');
      debugPrint(
        '   Time: ${scheduledTime.toLocal()} (${scheduledTime.timeZoneName})',
      );
      debugPrint('   Next trigger: ${_formatDateTime(scheduledTime)}');
    } catch (e) {
      debugPrint('❌ Error scheduling notification $id: $e');
    }
  }

  /// Show an instant notification (for testing purposes)
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final int notificationId = Random().nextInt(1 << 31);

      await _notifications.show(
        notificationId,
        title,
        body,
        _getSilentNotificationDetails(),
        payload: payload ?? 'instant_${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint('📱 Instant notification shown');
      debugPrint('   ID: $notificationId');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
    } catch (e) {
      debugPrint('❌ Error showing instant notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('📱 All notifications cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('📱 Notification $id cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling notification $id: $e');
    }
  }

  /// Cancel all daily challenge notifications
  Future<void> cancelDailyChallengeNotifications() async {
    try {
      await cancelNotification(morningNotificationId);
      await cancelNotification(afternoonNotificationId);
      await cancelNotification(eveningNotificationId);
      debugPrint('📱 Daily challenge notifications cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling daily challenge notifications: $e');
    }
  }

  /// Get list of all pending scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('📱 Found ${pending.length} pending notifications');

      for (final notification in pending) {
        debugPrint('   - ID: ${notification.id}');
        debugPrint('     Title: ${notification.title}');
        debugPrint('     Body: ${notification.body}');
      }

      return pending;
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled for this app
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? enabled = await androidPlugin?.areNotificationsEnabled();
      debugPrint('📱 Notifications enabled: $enabled');
      return enabled ?? false;
    } catch (e) {
      debugPrint('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// Disable all notifications (cancel and stop scheduling)
  Future<void> disableNotifications() async {
    try {
      await cancelAllNotifications();
      debugPrint('📱 All notifications disabled successfully');
    } catch (e) {
      debugPrint('❌ Error disabling notifications: $e');
    }
  }





  /// Test notification functionality
  Future<void> testNotifications() async {
    try {
      debugPrint('🧪 Starting notification test...');

      // Show instant test notification
      await showInstantNotification(
        title: '🧪 Test Notification',
        body: 'This is a test notification in silent mode.',
        payload: 'test_notification',
      );

      // Schedule a test notification for 1 minute from now
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(minutes: 1));

      await _notifications.zonedSchedule(
        9999, // Test notification ID
        '⏰ Test Scheduled Notification',
        'This notification was scheduled for 1 minute after test.',
        testTime,
        _getSilentNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🧪 Test notifications scheduled');
      debugPrint('   Instant notification: Shown immediately');
      debugPrint('   Scheduled notification: ${_formatDateTime(testTime)}');

      // Show pending count
      final pending = await getPendingNotifications();
      debugPrint('🧪 Total pending after test: ${pending.length}');
    } catch (e) {
      debugPrint('❌ Error during notification test: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final pending = await getPendingNotifications();
      final enabled = await areNotificationsEnabled();
      final localTime = tz.TZDateTime.now(tz.local);

      return {
        'enabled': enabled,
        'pendingCount': pending.length,
        'timezone': localTime.timeZoneName,
        'currentLocalTime': localTime.toString(),
        'pendingNotifications': pending
            .map((n) => {'id': n.id, 'title': n.title, 'body': n.body})
            .toList(),
      };
    } catch (e) {
      debugPrint('❌ Error getting notification stats: $e');
      return {'error': e.toString()};
    }
  }

  // PRIVATE HELPER METHODS

  /// Compute next local occurrence of hour:minute in device timezone
  tz.TZDateTime _nextInstanceLocal(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // The timezone package handles DST transitions correctly
    return scheduled;
  }

  /// Get notification details configured for silent delivery
  NotificationDetails _getSilentNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low, // Low = no popup, no sound
        priority: Priority.low, // Low priority
        enableVibration: false, // No vibration
        playSound: false, // No sound
        silent: true, // Explicitly silent
        showWhen: false, // Don't show timestamp
        ongoing: false, // Not persistent notification
        autoCancel: true, // Auto dismiss when tapped
        icon: '@mipmap/ic_launcher', // Use app icon
        color: Color(0xFF1976D2), // Brand color for notification
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.private,
      ),
    );
  }

  /// Format datetime for logging
  String _formatDateTime(tz.TZDateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')} '
        '${dateTime.timeZoneName}';
  }
}
