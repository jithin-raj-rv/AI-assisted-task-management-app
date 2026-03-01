import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/Notification/awesome_notification_service.dart';
import 'package:to_do_list/cache/scheduled_notification_cache.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/services/foreground_service_manager.dart';
import 'package:to_do_list/services/reminder_sync_service.dart';

void foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

class ForegroundTaskHandler extends TaskHandler {
  AwesomeNotificationService? _localNotificationService;
  ReminderSyncService? _reminderSyncService;
  ScheduledNotificationCache? _cache;
  ForegroundServiceManager? _foregroundServiceManager;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Hive if not already done
      await Hive.initFlutter();
      
      // Open required Hive boxes
      await Hive.openBox('scheduled_notifications');
      await Hive.openBox('settings');
      
      // Initialize services
      _localNotificationService = AwesomeNotificationService();
      await _localNotificationService!.init();
      
      _reminderSyncService = ReminderSyncService(ConnectivityService());
      _cache = ScheduledNotificationCache();
      _foregroundServiceManager = ForegroundServiceManager();
      
      _isInitialized = true;
      print('[ForegroundTaskHandler] Initialization complete');
    } catch (e) {
      print('[ForegroundTaskHandler] Initialization error: $e');
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    print('[ForegroundTaskHandler] onStart called');
    await _ensureInitialized();
    
    try {
      await _reminderSyncService!.syncFromSupabase();
      final reminders = await _cache!.getAll();
      
      print('[ForegroundTaskHandler] Found ${reminders.length} reminders in cache');
      
      // Filter to only future reminders for scheduling
      final now = DateTime.now();
      final futureReminders = reminders.where((r) => r.scheduledDate.isAfter(now)).toList();
      print('[ForegroundTaskHandler] Scheduling ${futureReminders.length} future reminders');
      
      await _localNotificationService!.rescheduleAllNotifications(futureReminders);
      await _foregroundServiceManager!.updateNotificationText(futureReminders.length);
    } catch (e) {
      print('Error onStart foreground task: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    print('[ForegroundTaskHandler] onRepeatEvent called at $timestamp');
    
    try {
      // Sync from Supabase to get latest reminders
      await _reminderSyncService!.syncFromSupabase();
      final reminders = await _cache!.getAll();
      
      print('[ForegroundTaskHandler] onRepeatEvent: Found ${reminders.length} reminders');
      
      // Filter to only future reminders
      final now = DateTime.now();
      final futureReminders = reminders.where((r) => r.scheduledDate.isAfter(now)).toList();
      
      // Reschedule all future notifications
      await _localNotificationService!.rescheduleAllNotifications(futureReminders);
      await _foregroundServiceManager!.updateNotificationText(futureReminders.length);
    } catch (e) {
      print('Error onRepeatEvent foreground task: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isUserStop) async {
    print('Foreground task destroyed. isUserStop: $isUserStop');
    if (isUserStop) {
      final box = await Hive.openBox('settings');
      await box.put('foreground_service_enabled', false);
    }
  }

  @override
  void onButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }
}
