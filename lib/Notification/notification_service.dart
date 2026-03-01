import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_list/models/scheduled_notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init({void Function(String?)? onNotificationResponse}) async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Reminders',
          channelDescription: 'Notification channel for reminders.',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
        ),
      ],
      debug: true,
    );

    // Listen for notification actions if a handler is provided
    if (onNotificationResponse != null) {
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: (receivedAction) async {
          onNotificationResponse(receivedAction.payload?['payload']);
        },
      );
    }
  }

  Future<bool> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        payload: payload != null ? {'payload': payload} : null,
      ),
    );
  }

  Future<void> showScheduledNotification({
    required ScheduledNotification notification,
  }) async {
    final scheduledTime = tz.TZDateTime.from(notification.scheduledDate, tz.local);

    print('[Notification] Scheduling: id=${notification.id}, time=$scheduledTime');

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notification.id.hashCode.abs(),
          channelKey: 'basic_channel',
          title: notification.title,
          body: notification.body,
          payload: notification.payload != null ? {'payload': notification.payload} : null,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime, preciseAlarm: true),
      );
      print('✅ [Notification] Scheduled successfully: ${notification.id}');
    } catch (e) {
      print('❌ [Notification] Scheduling failed for ${notification.id}: $e');
    }
  }

  Future<void> cancelNotification(String notificationId) async {
    await AwesomeNotifications().cancel(notificationId.hashCode.abs());
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> rescheduleAllNotifications(
      List<ScheduledNotification> notifications) async {
    await cancelAllNotifications();
    final now = DateTime.now();

    for (final notification in notifications) {
      // Only schedule notifications that are in the future
      if (notification.scheduledDate.isAfter(now)) {
        await showScheduledNotification(notification: notification);
      } else {
        print('[Notification] Skipping past notification: ${notification.id}');
      }
    }
  }

  Future<bool> canScheduleExactNotifications() async {
    // This is a workaround to check for exact alarm permissions.
    // It tries to schedule a notification in the near future and checks for an error.
    try {
      final now = DateTime.now().add(const Duration(seconds: 1));
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999999, // A temporary ID
          channelKey: 'basic_channel',
          title: 'Permission Check',
          body: 'Checking exact alarm permission.',
        ),
        schedule: NotificationCalendar(
          year: now.year,
          month: now.month,
          day: now.day,
          hour: now.hour,
          minute: now.minute,
          second: now.second,
          preciseAlarm: true,
        ),
      );
      // If it succeeds, cancel it immediately and return true.
      await AwesomeNotifications().cancel(999999);
      return true;
    } catch (e) {
      // If it fails, it's likely due to missing permissions.
      print('Could not schedule exact notification, likely due to missing permissions: $e');
      return false;
    }
  }
}
