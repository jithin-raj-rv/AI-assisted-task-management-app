import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/services/user_device_service.dart';
import 'package:to_do_list/services/connectivity_service.dart';

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
          final originalPayload = receivedAction.payload?['payload'];
          var payloadToSend = originalPayload;
          // If the user pressed an action button, append the action key so
          // callers can distinguish which option was chosen.
          if (receivedAction.buttonKeyPressed != null) {
            payloadToSend = '${originalPayload ?? ''}||action:${receivedAction.buttonKeyPressed}';
          }
          onNotificationResponse(payloadToSend);
        },
      );
    }
  }

  Future<bool> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    print('[Notification] Current permission status: $isAllowed');
    
    if (!isAllowed) {
      print('[Notification] Requesting notification permission...');
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      print('[Notification] Permission request result: $isAllowed');
      
      if (isAllowed) {
        print('[Notification] ✅ Notification permission granted');
      } else {
        print('[Notification] ❌ Notification permission denied');
      }
    } else {
      print('[Notification] ✅ Notification permission already granted');
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
      // Build action buttons from provided options (if any)
      final actionButtons = <NotificationActionButton>[];
      if (notification.options != null && notification.options!.isNotEmpty) {
        for (var i = 0; i < notification.options!.length; i++) {
          final opt = notification.options![i];
          // Use the option text as both key and label so the pressed key
          // maps directly to the option string.
          actionButtons.add(NotificationActionButton(key: opt, label: opt, actionType: ActionType.Default));
        }
      }

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
        actionButtons: actionButtons.isNotEmpty ? actionButtons : null,
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
    bool hasFutureNotifications = false;

    for (final notification in notifications) {
      // Only schedule notifications that are in the future
      if (notification.scheduledDate.isAfter(now)) {
        await showScheduledNotification(notification: notification);
        hasFutureNotifications = true;
      } else {
        print('[Notification] Skipping past notification: ${notification.id}');
      }
    }

    // Mark device as scheduled if there are future notifications
    if (hasFutureNotifications) {
      try {
        final connectivityService = ConnectivityService();
        final userDeviceService = UserDeviceService(connectivityService);
        await userDeviceService.markAsScheduled();
        print('[Notification] Marked device as scheduled due to future notifications');
      } catch (e) {
        print('[Notification] Failed to mark device as scheduled: $e');
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
