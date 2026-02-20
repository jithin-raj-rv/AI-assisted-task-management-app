import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fgt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:to_do_list/foreground_task_handler.dart';

final foregroundServiceManagerProvider = Provider<ForegroundServiceManager>((ref) {
  return ForegroundServiceManager();
});

final foregroundServiceRunningProvider = FutureProvider<bool>((ref) async {
  final manager = ref.watch(foregroundServiceManagerProvider);
  return await manager.isRunning();
});

class ForegroundServiceManager {
  final _box = Hive.box('settings');
  static const String _serviceEnabledKey = 'foreground_service_enabled';

  bool get isServiceEnabled => _box.get(_serviceEnabledKey, defaultValue: false);

  Future<void> setServiceEnabled(bool enabled) async {
    await _box.put(_serviceEnabledKey, enabled);
    if (enabled) {
      await startService();
    } else {
      await stopService();
    }
  }

  Future<bool> isRunning() async {
    try {
      return await fgt.FlutterForegroundTask.isRunningService;
    } catch (e) {
      return false;
    }
  }

  /// Request battery optimization exemption via platform channel
  /// This opens the battery optimization settings so user can manually exempt the app
  Future<void> requestBatteryOptimizationExemption() async {
    try {
      // Use platform channel to request battery optimization exemption
      const platform = MethodChannel('to_do_list/battery');
      await platform.invokeMethod('requestBatteryExemption');
      print('[ForegroundServiceManager] Battery exemption requested via platform channel');
    } catch (e) {
      print('[ForegroundServiceManager] Platform channel error (this is normal if not implemented): $e');
      // Fallback: The user will need to manually disable battery optimization
      // This is expected behavior on most devices
    }
  }

  Future<void> startService() async {
    try {
      // Check if already running
      if (await isRunning()) {
        print('Foreground service already running');
        return;
      }

      print('Starting foreground service...');
      
      await fgt.FlutterForegroundTask.startService(
        notificationTitle: 'Todo App Active',
        notificationText: 'Monitoring your reminders in background',
        callback: foregroundTaskCallback,
        notificationButtons: [fgt.NotificationButton(id: 'stop', text: 'Stop')],
      );
      
      print('Foreground service started successfully');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  Future<void> stopService() async {
    try {
      if (await isRunning()) {
        await fgt.FlutterForegroundTask.stopService();
        print('Foreground service stopped');
      }
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }

  Future<void> updateNotificationText(int upcomingReminders) async {
    try {
      if (await isRunning()) {
        await fgt.FlutterForegroundTask.updateService(
          notificationTitle: 'Todo App Active',
          notificationText: 'You have $upcomingReminders upcoming reminders.',
        );
      }
    } catch (e) {
      print('Error updating notification text: $e');
    }
  }

  Future<void> init() async {
    // Small delay to ensure the app is fully initialized
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (isServiceEnabled) {
      print('Restoring foreground service on app start...');
      await startService();
    }
  }
}
