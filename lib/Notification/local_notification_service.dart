import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:to_do_list/models/scheduled_notification_model.dart'; // Import for initializing timezone data
import 'dart:convert';

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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showScheduledNotification({
    required ScheduledNotification notification,
  }) async {
    // Basic details
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    // Modify based on reminder type
    if (notification.reminderType == ReminderType.option &&
        notification.options != null &&
        notification.options!.isNotEmpty) {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        actions: notification.options!
            .map((option) => AndroidNotificationAction(option, option))
            .toList(),
      );
    } else if (notification.reminderType == ReminderType.answerBack) {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
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
    }

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _convertIdTo32Bit(notification.id),
      notification.title,
      notification.body,
      // Ensure we interpret the scheduledDate as local wall-clock time
      tz.TZDateTime.from(notification.scheduledDate.toLocal(), tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: notification.payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAllNotifications(
      List<ScheduledNotification> notifications) async {
    await cancelAllNotifications();
    final now = DateTime.now();
    
    for (var notification in notifications) {
      // Only reschedule notifications that are scheduled for the future
      if (notification.scheduledDate.isAfter(now)) {
        await showScheduledNotification(notification: notification);
      } else {
        print('Skipping past notification: ${notification.id} scheduled for ${notification.scheduledDate}');
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
}
