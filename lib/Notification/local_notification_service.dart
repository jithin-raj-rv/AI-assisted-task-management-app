import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:to_do_list/models/scheduled_notification_model.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();
  void Function(String?)? _onNotificationResponse;

  /// Convert a string ID to a valid 32-bit signed integer
  /// If the ID is too large, hash it to fit within the 32-bit range
  int _convertIdTo32Bit(String id) {
    try {
      final parsedId = int.parse(id);
      // Check if it's within 32-bit signed integer range
      if (parsedId >= -2147483648 && parsedId <= 2147483647) {
        return parsedId;
      }
      // If out of range, hash it and use modulo to fit within range
      final hash = id.hashCode;
      return hash.toSigned(32);
    } catch (e) {
      // If parsing fails, hash the string ID and use modulo
      final hash = id.hashCode;
      return hash.toSigned(32);
    }
  }

  Future<void> init({void Function(String?)? onNotificationResponse}) async {
    tz.initializeTimeZones(); // Initialize timezone data
    _onNotificationResponse = onNotificationResponse;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          onNotificationClick.add(payload);
        }
        _onNotificationResponse?.call(payload);
        if (response.input?.isNotEmpty ?? false) {
          print('Notification response with input: ${response.input}');
        }
      },
    );

    // Create notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id',
      'your_channel_name',
      description: 'your_channel_description',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    // display a dialog with the notification details, tap ok to go to another page
    if (payload != null) {
      onNotificationClick.add(payload);
      _onNotificationResponse?.call(payload);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF0000FF),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    print('Showing notification: id=$id, title=$title, body=$body');

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    print('Notification show completed');
  }

  Future<void> showScheduledNotification({
    required ScheduledNotification notification,
  }) async {
    final now = DateTime.now();
    final notificationId = notification.id;
    final scheduledDate = notification.scheduledDate;
    final timeUntilNotification = scheduledDate.difference(now);
    
    print('╔═══════════════════════════════════════════════════════════════');
    print('║ [LocalNotification] NEW NOTIFICATION SCHEDULE REQUEST');
    print('║ Notification ID: $notificationId');
    print('║ Title: ${notification.title}');
    print('║ Scheduled Date (UTC): $scheduledDate');
    print('║ Current Time: $now');
    print('║ Time Until Notification: ${timeUntilNotification.inMinutes} minutes');
    print('║ Is In Past: ${scheduledDate.isBefore(now)}');
    print('╚═══════════════════════════════════════════════════════════════');
    
    // If notification is in the past, show immediately
    if (scheduledDate.isBefore(now)) {
      print('[LocalNotification] ⚠️ Notification is in the past, showing immediately!');
      await showNotification(
        id: _convertIdTo32Bit(notificationId),
        title: notification.title,
        body: notification.body ?? 'Reminder',
        payload: notification.payload,
      );
      print('[LocalNotification] ✓ Shown as immediate notification');
      return;
    }
    
    // Basic details with more robust settings for background
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.max, // Use MAX priority for reliability
      ticker: 'ticker',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    // Modify based on reminder type
    AndroidNotificationDetails finalAndroidDetails;
    
    if (notification.reminderType == ReminderType.option &&
        notification.options != null &&
        notification.options!.isNotEmpty) {
      finalAndroidDetails = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ticker',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        actions: notification.options!
            .map((option) => AndroidNotificationAction(option, option))
            .toList(),
      );
    } else if (notification.reminderType == ReminderType.answerBack) {
      finalAndroidDetails = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ticker',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        actions: [
          AndroidNotificationAction(
            'reply',
            'Reply',
            inputs: [
              AndroidNotificationActionInput(
                label: 'Enter your message',
              ),
            ],
          ),
        ],
      );
    } else {
      finalAndroidDetails = androidPlatformChannelSpecifics;
    }

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: finalAndroidDetails);

    // Convert to local timezone
    final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
    print('[LocalNotification] Converted to local timezone: $scheduledTime');

    // Check if we have permission to schedule exact alarms
    bool? canScheduleExact = await canScheduleExactNotifications();
    print('[LocalNotification] Permission check - Can schedule exact: $canScheduleExact');

    // ════════════════════════════════════════════════════════════════
    // METHOD 1: Try exactAllowWhileIdle (MOST RELIABLE)
    // ════════════════════════════════════════════════════════════════
    print('[LocalNotification] Trying METHOD 1: exactAllowWhileIdle...');
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _convertIdTo32Bit(notificationId),
        notification.title,
        notification.body,
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: notification.payload,
        matchDateTimeComponents: null,
      );
      print('╔═══════════════════════════════════════════════════════════════');
      print('║ ✅ SUCCESS! Notification scheduled with exactAllowWhileIdle');
      print('║ ID: $notificationId');
      print('║ Will fire at: $scheduledTime');
      print('╚═══════════════════════════════════════════════════════════════');
      return;
    } catch (e) {
      print('[LocalNotification] ❌ METHOD 1 FAILED: $e');
    }

    // ════════════════════════════════════════════════════════════════
    // METHOD 2: Try inexactAllowWhileIdle (FALLBACK)
    // ════════════════════════════════════════════════════════════════
    print('[LocalNotification] Trying METHOD 2: inexactAllowWhileIdle...');
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _convertIdTo32Bit(notificationId),
        notification.title,
        notification.body,
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: notification.payload,
      );
      print('╔═══════════════════════════════════════════════════════════════');
      print('║ ✅ SUCCESS! Notification scheduled with inexactAllowWhileIdle');
      print('║ ID: $notificationId');
      print('║ Will fire at: $scheduledTime (approximate)');
      print('╚═══════════════════════════════════════════════════════════════');
      return;
    } catch (e) {
      print('[LocalNotification] ❌ METHOD 2 FAILED: $e');
    }

    // ════════════════════════════════════════════════════════════════
    // METHOD 3: LAST RESORT - Show immediately
    // ════════════════════════════════════════════════════════════════
    print('[LocalNotification] ⚠️ All scheduling methods failed!');
    print('[LocalNotification] Falling back to showing notification immediately...');
    
    try {
      await showNotification(
        id: _convertIdTo32Bit(notificationId),
        title: notification.title,
        body: notification.body ?? 'Reminder',
        payload: notification.payload,
      );
      print('╔═══════════════════════════════════════════════════════════════');
      print('║ ⚠️ FALLBACK: Shown as immediate notification (NOT SCHEDULED)');
      print('║ This means scheduled notifications may not work!');
      print('║ Check: Notification permission, Exact alarm permission,');
      print('║        Battery optimization settings');
      print('╚═══════════════════════════════════════════════════════════════');
    } catch (e3) {
      print('[LocalNotification] 💀 ALL METHODS FAILED: $e3');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Helper to cancel by the original string ID used in ScheduledNotification
  Future<void> cancelNotificationByStringId(String id) async {
    final int32 = _convertIdTo32Bit(id);
    await cancelNotification(int32);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAllNotifications(
      List<ScheduledNotification> notifications) async {
    await cancelAllNotifications();
    final now = DateTime.now();

    for (var notification in notifications) {
      // If notification is in the future, schedule it
      if (notification.scheduledDate.isAfter(now)) {
        try {
          await showScheduledNotification(notification: notification);
        } catch (e) {
          print('Failed to schedule notification ${notification.id}: $e');
        }
      } 
      // If notification is in the past but within the last 5 minutes, show it immediately
      // This handles cases where the app was suspended/killed when the notification should have fired
      else if (now.difference(notification.scheduledDate).inMinutes < 5) {
        print('Showing recent past notification immediately: ${notification.id} scheduled for ${notification.scheduledDate}');
        try {
          await showNotification(
            id: _convertIdTo32Bit(notification.id),
            title: notification.title,
            body: notification.body!,
            payload: notification.payload,
          );
        } catch (e) {
          print('Failed to show recent past notification ${notification.id}: $e');
        }
      } else {
        print('Skipping old past notification: ${notification.id} scheduled for ${notification.scheduledDate}');
      }
    }
  }

  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    String? payload,
    required List<AndroidNotificationAction> actions,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: actions,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showNotificationWithTextResponse({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: [
        AndroidNotificationAction(
          'reply',
          'Reply',
          inputs: [
            AndroidNotificationActionInput(
              label: 'Enter your message',
            ),
          ],
        ),
      ],
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<bool?> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
    final notificationsGranted = await androidPlugin?.requestNotificationsPermission();
    final exactAlarmsGranted = await androidPlugin?.requestExactAlarmsPermission();
    return notificationsGranted == true && exactAlarmsGranted == true;
  }

  Future<bool?> canScheduleExactNotifications() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.canScheduleExactNotifications();
  }
}
