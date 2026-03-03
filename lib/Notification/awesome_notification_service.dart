import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';

class AwesomeNotificationService {
  final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();
  void Function(String?)? _onNotificationResponse;

  /// Convert a string ID to a valid positive 32-bit signed integer
  /// If the ID is too large or negative, hash it to fit within the positive 32-bit range
  int _convertIdTo32Bit(String id) {
    try {
      final parsedId = int.parse(id);
      // Check if it's within 32-bit signed integer range and positive
      if (parsedId > 0 && parsedId <= 2147483647) {
        return parsedId;
      }
      // If out of range or negative, hash it and ensure positive
      final hash = id.hashCode;
      final positiveHash = hash.abs();
      return positiveHash % 2147483647;
    } catch (e) {
      // If parsing fails, hash the string ID and ensure positive
      final hash = id.hashCode;
      final positiveHash = hash.abs();
      return positiveHash % 2147483647;
    }
  }

  Future<void> init({void Function(String?)? onNotificationResponse}) async {
    _onNotificationResponse = onNotificationResponse;

    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelGroupKey: 'reminder_channel_group',
          channelKey: 'reminder_channel',
          channelName: 'Reminders',
          channelDescription: 'Reminder notifications for your tasks',
          defaultColor: const Color(0xFF00FF00),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          locked: false,
          onlyAlertOnce: false,
          groupKey: 'reminder_group',
          // Add small icon configuration for better compatibility
          icon: 'resource://drawable/ic_notification',
        )
      ],
    );

    // Handle notification actions
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (receivedNotification) async {
        final payload = receivedNotification.payload?['payload'];
        if (payload != null) {
          onNotificationClick.add(payload);
          _onNotificationResponse?.call(payload);
        }
        
        // Handle action buttons
        if (receivedNotification.buttonKeyPressed != null) {
          final action = receivedNotification.buttonKeyPressed;
          final notificationId = receivedNotification.id.toString();
          print('Notification action pressed: $action for notification: $notificationId');
        }
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('Showing notification: id=$id, title=$title, body=$body');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminder_channel',
        title: title,
        body: body,
        payload: payload != null ? {'payload': payload} : null,
        category: NotificationCategory.Reminder,
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        notificationLayout: NotificationLayout.BigText,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          autoDismissible: true,
          enabled: true,
        ),
      ],
    );

    print('Notification show completed');
  }

  /// Schedule a notification immediately when it's created
  /// This ensures notifications are scheduled locally without relying on background services
  Future<void> scheduleNotificationImmediately({
    required ScheduledNotification notification,
  }) async {
    final now = DateTime.now();
    final scheduledDate = notification.scheduledDate;
    final timeUntilNotification = scheduledDate.difference(now);
    
    print('╔═══════════════════════════════════════════════════════════════');
    print('║ [AwesomeNotification] IMMEDIATE SCHEDULE REQUEST');
    print('║ Notification ID: ${notification.id}');
    print('║ Title: ${notification.title}');
    print('║ Scheduled Date (UTC): $scheduledDate');
    print('║ Current Time: $now');
    print('║ Time Until Notification: ${timeUntilNotification.inMinutes} minutes');
    print('║ Is In Past: ${scheduledDate.isBefore(now)}');
    print('╚═══════════════════════════════════════════════════════════════');
    
    // Only schedule if the notification is in the future
    if (scheduledDate.isBefore(now)) {
      print('⚠️  Notification is in the past, skipping immediate schedule');
      return;
    }

    try {
      await showScheduledNotification(notification: notification);
      print('✅ Notification scheduled successfully');
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
    }
  }

  Future<void> showScheduledNotification({
    required ScheduledNotification notification,
  }) async {
    final now = DateTime.now();
    final notificationId = notification.id;
    final scheduledDate = notification.scheduledDate;
    final timeUntilNotification = scheduledDate.difference(now);
    
    print('╔═══════════════════════════════════════════════════════════════');
    print('║ [AwesomeNotification] NEW NOTIFICATION SCHEDULE REQUEST');
    print('║ Notification ID: $notificationId');
    print('║ Title: ${notification.title}');
    print('║ Scheduled Date (UTC): $scheduledDate');
    print('║ Current Time: $now');
    print('║ Time Until Notification: ${timeUntilNotification.inMinutes} minutes');
    print('║ Is In Past: ${scheduledDate.isBefore(now)}');
    print('╚═══════════════════════════════════════════════════════════════');
    
    // Convert to local timezone
    final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
    print('[AwesomeNotification] Converted to local timezone: $scheduledTime');

    // Create notification content
    NotificationContent notificationContent = NotificationContent(
      id: _convertIdTo32Bit(notificationId),
      channelKey: 'reminder_channel',
      title: notification.title,
      body: notification.body,
      payload: notification.payload != null ? {'payload': notification.payload} : null,
      category: NotificationCategory.Reminder,
      displayOnBackground: true,
      displayOnForeground: true,
      wakeUpScreen: true,
      fullScreenIntent: true,
      autoDismissible: false,
      notificationLayout: NotificationLayout.BigText,
    );

    // Modify based on reminder type
    List<NotificationActionButton> actionButtons = [
      NotificationActionButton(
        key: 'DISMISS',
        label: 'Dismiss',
        autoDismissible: true,
        enabled: true,
      ),
    ];

    if (notification.reminderType == ReminderType.option &&
        notification.options != null &&
        notification.options!.isNotEmpty) {
      // Add option buttons
      actionButtons.addAll(
        notification.options!.map((option) => NotificationActionButton(
          key: option,
          label: option,
          autoDismissible: true,
          enabled: true,
        )).toList(),
      );
    } else if (notification.reminderType == ReminderType.answerBack) {
      // Add reply action
      actionButtons.add(
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: false,
          enabled: true,
        ),
      );
    } else if (notification.reminderType == ReminderType.aiPrompt) {
      // Add AI prompt action
      actionButtons.add(
        NotificationActionButton(
          key: 'AI_PROMPT',
          label: 'View Prompt',
          autoDismissible: true,
          enabled: true,
        ),
      );
    }

    try {
      await AwesomeNotifications().createNotification(
        content: notificationContent,
        actionButtons: actionButtons,
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: scheduledTime.second,
          millisecond: scheduledTime.millisecond,
          preciseAlarm: true, // Use precise alarm for better accuracy
        ),
      );
      
      print('╔═══════════════════════════════════════════════════════════════');
      print('║ ✅ SUCCESS! Notification scheduled with Awesome Notifications');
      print('║ ID: $notificationId');
      print('║ Will fire at: $scheduledTime');
      print('╚═══════════════════════════════════════════════════════════════');
    } catch (e) {
      print('[AwesomeNotification] ❌ SCHEDULING FAILED: $e');
      print('[AwesomeNotification] This may be due to permission issues or system restrictions');
    }
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Helper to cancel by the original string ID used in ScheduledNotification
  Future<void> cancelNotificationByStringId(String id) async {
    final int32 = _convertIdTo32Bit(id);
    await cancelNotification(int32);
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
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
          if (notification.reminderType == ReminderType.option &&
              notification.options != null &&
              notification.options!.isNotEmpty) {
            List<NotificationActionButton> actionButtons = notification.options!
                .map((option) => NotificationActionButton(
                      key: option,
                      label: option,
                      autoDismissible: true,
                      enabled: true,
                    ))
                .toList();
            actionButtons.add(NotificationActionButton(
              key: 'DISMISS',
              label: 'Dismiss',
              autoDismissible: true,
              enabled: true,
            ));
            await showNotificationWithActions(
              id: _convertIdTo32Bit(notification.id),
              title: notification.title,
              body: notification.body!,
              payload: notification.payload,
              actions: actionButtons,
            );
          } else {
            await showNotification(
              id: _convertIdTo32Bit(notification.id),
              title: notification.title,
              body: notification.body!,
              payload: notification.payload,
            );
          }
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
    required List<NotificationActionButton> actions,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminder_channel',
        title: title,
        body: body,
        payload: payload != null ? {'payload': payload} : null,
        category: NotificationCategory.Reminder,
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        notificationLayout: NotificationLayout.BigText,
      ),
      actionButtons: actions,
    );
  }

  Future<void> showNotificationWithTextResponse({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminder_channel',
        title: title,
        body: body,
        payload: payload != null ? {'payload': payload} : null,
        category: NotificationCategory.Reminder,
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        notificationLayout: NotificationLayout.BigText,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          autoDismissible: false,
          enabled: true,
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          autoDismissible: true,
          enabled: true,
        ),
      ],
    );
  }

  Future<bool> requestPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<bool> canScheduleExactNotifications() async {
    // Awesome Notifications handles scheduling internally
    // Check if we can create scheduled notifications
    try {
      final now = DateTime.now().add(Duration(seconds: 1));
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999999,
          channelKey: 'reminder_channel',
          title: 'Test',
          body: 'Test',
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
      await AwesomeNotifications().cancel(999999);
      return true;
    } catch (e) {
      return false;
    }
  }
}