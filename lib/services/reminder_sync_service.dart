import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/scheduled_notification_cache.dart';
import 'package:to_do_list/main.dart';
import 'package:to_do_list/services/user_device_service.dart';

class ReminderSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final ScheduledNotificationCache _cache = ScheduledNotificationCache();

  List<dynamic> _activeChannels = [];

  ReminderSyncService(this._connectivityService);

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

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[ReminderSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final remindersData = await _supabase.from('reminders').select('*').eq('user_id', user.id) as List;
      print('[ReminderSync] Fetched ${remindersData.length} reminders from Supabase');
      for (var i = 0; i < remindersData.length; i++) {
        print('[ReminderSync] Reminder $i: id=${remindersData[i]['id']} (${remindersData[i]['id'].runtimeType}), title=${remindersData[i]['title']}, type=${remindersData[i]['reminder_type']}, options=${remindersData[i]['options']} (${remindersData[i]['options']?.runtimeType})');
      }
      final reminders = remindersData.map((r) {
        // Parse options - handle both List<dynamic> and List<String> from Supabase
        List<String>? options;
        final rawOptions = r['options'];
        if (rawOptions != null) {
          if (rawOptions is List) {
            options = rawOptions.map((e) => e.toString()).toList();
          }
        }
        return ScheduledNotification(
          id: r['id']?.toString() ?? '',  // Explicitly convert to String
          title: r['title'] ?? '',
          body: r['body'],
          scheduledDate: r['scheduled_date'] != null ? DateTime.parse(r['scheduled_date']) : DateTime.now(),
          payload: r['payload'] ?? '',
          reminderType: _parseReminderType(r['reminder_type']),
          options: options,
          expectedAnswer: r['expected_answer'],
          aiPrompt: r['ai_prompt'],
          userId: r['user_id'],
          createdAt: r['created_at'] != null ? DateTime.parse(r['created_at']) : null,
          updatedAt: r['updated_at'] != null ? DateTime.parse(r['updated_at']) : null,
        );
      }).toList();

      final box = await Hive.openBox<ScheduledNotification>('scheduled_notifications');
      final newReminders = {for (var reminder in reminders) reminder.id: reminder};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newReminders.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      if (newReminders.isNotEmpty) {
        box.putAll(newReminders);
      }

      // Mark device as scheduled if there are future reminders
      bool hasFutureReminders = false;
      final now = DateTime.now();
      for (final reminder in reminders) {
        if (reminder.scheduledDate.isAfter(now)) {
          hasFutureReminders = true;
          break;
        }
      }

      if (hasFutureReminders) {
        try {
          final userDeviceService = UserDeviceService(_connectivityService);
          // Set to false to trigger queue process on database side if needed
          await userDeviceService.triggerQueueProcessing();
          print('[ReminderSync] Triggered queue processing due to future reminders found during sync');
        } catch (e) {
          print('[ReminderSync] Failed to trigger queue processing during sync: $e');
        }
      }
    } catch (e) {
      print('[ReminderSync] Error syncing reminders: $e');
    }
  }

  ReminderType _parseReminderType(String? type) {
    switch (type) {
      case 'basic':
        return ReminderType.basic;
      case 'option':
        return ReminderType.option;
      case 'answer_back':
        return ReminderType.answerBack;
      case 'ai_prompt':
        return ReminderType.aiPrompt;
      default:
        return ReminderType.basic;
    }
  }

  String _reminderTypeToString(ReminderType type) {
    switch (type) {
      case ReminderType.basic:
        return 'basic';
      case ReminderType.option:
        return 'option';
      case ReminderType.answerBack:
        return 'answer_back';
      case ReminderType.aiPrompt:
        return 'ai_prompt';
      default:
        return 'basic';
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final remindersChannel = _supabase.channel('reminders_realtime');
    _activeChannels.add(remindersChannel);
    print('[ReminderSync] Setting up real-time subscription for user: ${user.id}');
    remindersChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'reminders',
      callback: (payload) async {
        print('[ReminderSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete' && record != null && record['user_id'] != user.id) return;
        print('[ReminderSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<ScheduledNotification>('scheduled_notifications');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[ReminderSync] Processing ${payload.eventType} for reminder id: ${record['id']}');
            print('[ReminderSync] Record fields: id=${record['id']}, title=${record['title']}, body=${record['body']}, scheduled_date=${record['scheduled_date']}, payload=${record['payload']}, reminder_type=${record['reminder_type']}, options=${record['options']}, expected_answer=${record['expected_answer']}, ai_prompt=${record['ai_prompt']}, user_id=${record['user_id']}');
            
            // Parse options - handle both List<dynamic> and List<String> from Supabase
            List<String>? options;
            final rawOptions = record['options'];
            if (rawOptions != null) {
              if (rawOptions is List) {
                options = rawOptions.map((e) => e.toString()).toList();
              }
            }
            
            final reminder = ScheduledNotification(
              id: record['id']?.toString() ?? '',  // Explicitly convert to String
              title: record['title'] ?? '',
              body: record['body'],
              scheduledDate: record['scheduled_date'] != null ? DateTime.parse(record['scheduled_date']) : DateTime.now(),
              payload: record['payload'],
              reminderType: _parseReminderType(record['reminder_type']),
              options: options,
              expectedAnswer: record['expected_answer'],
              aiPrompt: record['ai_prompt'],
              userId: record['user_id'],
              createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : null,
              updatedAt: record['updated_at'] != null ? DateTime.parse(record['updated_at']) : null,
            );
            print('[ReminderSync] Created reminder object: $reminder');
            box.put(reminder.id, reminder);
            print('[ReminderSync] Updated cache for reminder: ${reminder.id}');
            print('[ReminderSync] Cache now has ${box.length} items');
            // Schedule the reminder with local notification service if it's in the future
            try {
              final now = DateTime.now();
              if (reminder.scheduledDate.isAfter(now)) {
                await localNotificationService.showScheduledNotification(notification: reminder);
                print('[ReminderSync] Scheduled local notification for: ${reminder.id} at ${reminder.scheduledDate}');
              } else {
                print('[ReminderSync] Not scheduling past reminder: ${reminder.id} scheduled for ${reminder.scheduledDate}');
              }
            } catch (e) {
              print('[ReminderSync] Failed to schedule local notification for ${reminder.id}: $e');
            }
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[ReminderSync] Processing DELETE for reminder id: ${record['id']}');
            box.delete(record['id']);
            print('[ReminderSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[ReminderSync] Error processing realtime: $e');
          print('[ReminderSync] Stack trace: $stack');
        }
      },
    );
    remindersChannel.subscribe();
  }

  /// Create reminder
  Future<void> createReminder(ScheduledNotification reminder) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': reminder.id,
      'user_id': currentUser.id,
      'title': reminder.title,
      'body': reminder.body,
      'scheduled_date': reminder.scheduledDate.toUtc().toIso8601String(),
      'payload': reminder.payload,
      'reminder_type': _reminderTypeToString(reminder.reminderType),
      'options': reminder.options,
      'expected_answer': reminder.expectedAnswer,
      'ai_prompt': reminder.aiPrompt,
    };

    await _supabase.from('reminders').insert(supabaseData);
    await _cache.put(reminder.id, reminder);
    
    // Schedule the notification immediately when created
    try {
      await localNotificationService.showScheduledNotification(notification: reminder);
      print('[ReminderSync] Notification scheduled immediately for: ${reminder.id}');
      
      // Trigger queue processing when a reminder is created
      try {
        final userDeviceService = UserDeviceService(_connectivityService);
        await userDeviceService.triggerQueueProcessing();
        print('[ReminderSync] Triggered queue processing for new reminder: ${reminder.id}');
      } catch (e) {
        print('[ReminderSync] Failed to trigger queue processing: $e');
      }
    } catch (e) {
      print('[ReminderSync] Failed to schedule notification immediately for ${reminder.id}: $e');
    }
  }

  /// Update reminder
  Future<void> updateReminder(String id, ScheduledNotification reminder) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'title': reminder.title,
      'body': reminder.body,
      'scheduled_date': reminder.scheduledDate.toUtc().toIso8601String(),
      'payload': reminder.payload,
      'reminder_type': _reminderTypeToString(reminder.reminderType),
      'options': reminder.options,
      'expected_answer': reminder.expectedAnswer,
      'ai_prompt': reminder.aiPrompt,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('reminders').update(supabaseData).eq('id', id);
    await _cache.put(id, reminder);
    
    // Reschedule the notification when updated
    try {
      // First cancel the existing notification
      await localNotificationService.cancelNotification(id);
      // Then schedule the updated notification
      await localNotificationService.showScheduledNotification(notification: reminder);
      print('[ReminderSync] Notification rescheduled for: ${reminder.id}');
      
      // Trigger queue processing when a reminder is updated
      try {
        final userDeviceService = UserDeviceService(_connectivityService);
        await userDeviceService.triggerQueueProcessing();
        print('[ReminderSync] Triggered queue processing for updated reminder: ${reminder.id}');
      } catch (e) {
        print('[ReminderSync] Failed to trigger queue processing: $e');
      }
    } catch (e) {
      print('[ReminderSync] Failed to reschedule notification for ${reminder.id}: $e');
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('reminders').delete().eq('id', id);
    await _cache.delete(id);
  }
}
