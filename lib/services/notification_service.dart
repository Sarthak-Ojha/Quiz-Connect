import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs for different times
  static const int morningNotificationId = 1001;
  static const int afternoonNotificationId = 1002;
  static const int eveningNotificationId = 1003;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));

      // Initialize notifications
      await _initializeNotifications();

      // Request permissions
      await _requestPermissions();

      debugPrint('📱 Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// Initialize notification settings
  Future<void> _initializeNotifications() async {
    // Android settings - completely silent
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings - completely silent
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: false, // No sound
        );

    // Combined settings
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for when notification is tapped
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap when app is running
  void _onNotificationTapped(NotificationResponse response) async {
    debugPrint('Silent notification tapped: ${response.payload}');
    // No vibration or sound - completely silent
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.requestNotificationsPermission();
      }

      if (Platform.isIOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: false, // No sound permission
        );
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  /// Enable silent notifications automatically
  Future<void> enableSilentNotifications() async {
    try {
      await _notifications.cancelAll();

      await _scheduleDailyNotification(
        id: morningNotificationId,
        hour: 8,
        minute: 0,
        title: '🌅 Good Morning!',
        body: 'Start your day with Quiz Master! Test your knowledge.',
      );

      await _scheduleDailyNotification(
        id: afternoonNotificationId,
        hour: 14,
        minute: 0,
        title: '☀️ Afternoon Brain Break!',
        body: 'Time for a quick quiz! Challenge yourself.',
      );

      await _scheduleDailyNotification(
        id: eveningNotificationId,
        hour: 17,
        minute: 0,
        title: '🌆 Evening Quiz Time!',
        body: 'End your day with knowledge! Play some quizzes.',
      );

      debugPrint('📅 Silent notifications scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error enabling silent notifications: $e');
    }
  }

  /// Schedule a single daily notification
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        _getCompletelysilentNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification $id: $e');
    }
  }

  /// Get next instance of the specified time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get completely silent notification details
  NotificationDetails _getCompletelysilentNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'quiz_reminders',
        'Quiz Reminders',
        channelDescription: 'Silent quiz reminder notifications',
        importance: Importance.low, // Low importance = silent
        priority: Priority.low, // Low priority = silent
        enableVibration: false, // No vibration
        playSound: false, // No sound
        silent: true, // Explicitly silent
        showWhen: false, // Don't show time
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1976D2),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true, // Show notification
        presentBadge: true, // Show badge
        presentSound: false, // No sound
      ),
    );
  }

  /// Show an instant notification (for testing)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _notifications.show(
        Random().nextInt(1000),
        title,
        body,
        _getCompletelysilentNotificationDetails(),
        payload: 'instant_notification',
      );
    } catch (e) {
      debugPrint('❌ Error showing instant notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }
}
