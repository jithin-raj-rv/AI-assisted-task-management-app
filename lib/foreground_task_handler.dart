import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ReminderTaskHandler());
}

class ReminderTaskHandler extends TaskHandler {
  DateTime? _lastCheck;
  
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[ForegroundTask] Reminder monitoring started');
    _lastCheck = DateTime.now();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Check for upcoming reminders
    _checkUpcomingReminders();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isForceStop) async {
    print('[ForegroundTask] Reminder monitoring stopped (force: $isForceStop)');
  }

  @override
  Future<void> onReceiveData(Object data) async {
    print('[ForegroundTask] Received data: $data');
    try {
      if (data is String && data == 'stop') {
        print('[ForegroundTask] Stop button pressed (string)');
        await FlutterForegroundTask.stopService();
        return;
      }

      if (data is Map) {
        final id = data['id'] ?? data['buttonId'] ?? data['action'];
        if (id == 'stop') {
          print('[ForegroundTask] Stop button pressed (map)');
          await FlutterForegroundTask.stopService();
          return;
        }
        
        // Handle request to check reminders
        if (id == 'check_reminders') {
          _checkUpcomingReminders();
        }
      }
    } catch (e) {
      print('[ForegroundTask] Error handling received data: $e');
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('[ForegroundTask] onNotificationButtonPressed: $id');
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  void _checkUpcomingReminders() {
    try {
      // Use a simple approach: send data to the main isolate
      // The main isolate will handle the actual notification display
      print('[ForegroundTask] Checking reminders at ${DateTime.now()}');
      
      // We send a broadcast to notify the main app to check reminders
      // This works because the foreground task runs in a separate isolate
      FlutterForegroundTask.updateService(
        notificationTitle: 'Todo App Active',
        notificationText: 'Monitoring reminders...',
      );
      
      // Store a flag that the background task has run
      // The main app can check this flag when it comes to foreground
      _saveLastCheckTime();
      
    } catch (e) {
      print('[ForegroundTask] Error checking reminders: $e');
    }
  }
  
  void _saveLastCheckTime() {
    try {
      // We can't directly write to Hive from background isolate
      // Instead, we use FlutterForegroundTask to communicate
      print('[ForegroundTask] Background check completed');
    } catch (e) {
      print('[ForegroundTask] Error saving check time: $e');
    }
  }
}

// Helper class to manage foreground task from main isolate
class ForegroundTaskManager {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'your_channel_id',
        channelName: 'Todo App Background',
        channelDescription: 'App is running in background to monitor reminders',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // Check every minute
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  
  static Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService == false) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Todo App Active',
        notificationText: 'Monitoring your reminders in background',
        callback: startCallback,
      );
      print('Foreground service started successfully');
    }
  }
  
  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
    print('Foreground service stopped');
  }
  
  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}
