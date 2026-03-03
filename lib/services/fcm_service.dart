import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/cache/scheduled_notification_cache.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/Notification/notification_service.dart';
import 'dart:math';
import 'dart:convert';

class FcmService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    await AwesomeNotificationsFcm().initialize(
      onFcmSilentDataHandle: myFcmSilentDataHandle,
      onFcmTokenHandle: myFcmTokenHandle,
      onNativeTokenHandle: myNativeTokenHandle,
      // This license key is necessary for iOS production apps
      licenseKeys: null, 
    );
  }

  /// Saves the FCM token to the Supabase database for the current user.
  Future<void> saveFCMToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('[FCM] User is not logged in. Cannot save FCM token.');
        return;
      }

      print('[FCM] Requesting FCM token for user: ${user.id}');
      final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('[FCM] Could not get FCM token (token is null or empty).');
        return;
      }

      print('[FCM] Got FCM token: $fcmToken');
      print('[FCM] Token length: ${fcmToken.length} characters');
      print('[FCM] Token starts with: ${fcmToken.substring(0, min(20, fcmToken.length))}...');
      
      // Check if token already exists for this user and this specific FCM token
      Map<String, dynamic>? existingDeviceRecord;
      try {
        existingDeviceRecord = await _supabase
          .from('user_devices')
          .select('id, fcm_token, is_scheduled, is_sent') // Select all relevant columns
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken)
          .maybeSingle(); // Use maybeSingle to handle no record found without throwing
      } catch (e) {
        // No existing record found for this fcmToken and user, which is expected for new devices
        print('[FCM] No existing device record found for user ${user.id} with token $fcmToken: $e');
        existingDeviceRecord = null;
      }

      bool isScheduled = existingDeviceRecord?['is_scheduled'] ?? false;
      bool isSent = existingDeviceRecord?['is_sent'] ?? false;

      // If a record exists but the FCM token in the record is different (shouldn't happen with .eq('fcm_token')),
      // or if no record exists, then it's a new device or a token refresh for a new entry.
      // The current logic using onConflict: 'fcm_token' ensures existing entry is updated or new is inserted.

      print('[FCM] Upserting to user_devices for user ${user.id} with token $fcmToken...');

      // Add device info for better debugging
      final deviceInfo = {
        'platform': 'flutter',
        'timestamp': DateTime.now().toIso8601String(),
        'token_length': fcmToken.length,
        'token_prefix': fcmToken.substring(0, min(10, fcmToken.length)),
      };

      final response = await _supabase.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': fcmToken,
        'device_info': deviceInfo,
        'is_scheduled': isScheduled, // Preserve existing or default to false
        'is_sent': isSent, // Preserve existing or default to false
      }, onConflict: 'fcm_token').select(); // Specify onConflict to update if fcm_token exists

      if (response.isEmpty) {
         print('[FCM] Upsert failed with no error (response is empty).');
      } else {
         print('[FCM] Successfully saved/updated FCM token for user ${user.id}, device $fcmToken');
         print('[FCM] Response: ${response.first}');
         print('[FCM] Token registration completed successfully');
      }
    } catch (e, stackTrace) {
      print('[FCM] Error saving FCM token: $e');
      print('[FCM] Stack trace: $stackTrace');
      
      // Retry logic for network errors
      if (e.toString().contains('Network') || e.toString().contains('timeout')) {
        print('[FCM] Network error detected, retrying in 3 seconds...');
        await Future.delayed(const Duration(seconds: 3));
        try {
          await saveFCMToken();
        } catch (retryError) {
          print('[FCM] Retry failed: $retryError');
        }
      }
    }
  }

  /// Enhanced method to save FCM token with better error handling
  Future<void> saveFCMTokenWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await saveFCMToken();
        print('[FCM] Token saved successfully on attempt $attempt');
        return;
      } catch (e) {
        print('[FCM] Attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }
      }
    }
    print('[FCM] All retry attempts failed');
  }

  /// Check if FCM token is already saved for the current user
  Future<bool> isTokenSaved() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return false;
      }

      final response = await _supabase
        .from('user_devices')
        .select('fcm_token')
        .eq('user_id', user.id)
        .eq('fcm_token', fcmToken)
        .maybeSingle();

      return response != null && response['fcm_token'] != null;
    } catch (e) {
      print('[FCM] Error checking if token is saved: $e');
      return false;
    }
  }
}

//Needs to be a top-level function
@pragma("vm:entry-point")
Future<void> myFcmSilentDataHandle(FcmSilentData fcmSilentData) async {
  print('"Silent data": ${fcmSilentData.toString()}');

  if (fcmSilentData.data != null && fcmSilentData.data!['type'] == 'sync_reminders') {
    print('[FCM] Received sync_reminders action');
    
    try {
      final String action = fcmSilentData.data!['action'] ?? 'immediate_send';
      final String remindersJson = fcmSilentData.data!['reminders'] ?? '[]';
      
      // We would ideally call ReminderSyncService to sync, but since we are in a background isolate,
      // we need to handle this manually or ensure dependencies are initialized.
      
      // Wait for a brief moment if needed (the prompt mentioned 30s wait, which is handled in pgmq)
      // Parse the JSON array of reminders
      final List<dynamic> remindersData = jsonDecode(remindersJson);
      
      for (var r in remindersData) {
        // Handle options
        List<String>? options;
        if (r['options'] != null) {
            if (r['options'] is List) {
               options = (r['options'] as List).map((e) => e.toString()).toList();
            } else if (r['options'] is String) {
               options = (r['options'] as String).split(',');
            }
        }
        
        final reminder = ScheduledNotification(
          id: r['id']?.toString() ?? '',
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
        
        // Save to local cache
        await ScheduledNotificationCache().put(reminder.id, reminder);
        
        if (action == 'immediate_send') {
          // If immediate send, fire the notification immediately
          await NotificationService().showScheduledNotification(notification: reminder);
        } else {
          // If schedule send, just schedule it using NotificationService (it handles its own scheduling logic)
          await NotificationService().showScheduledNotification(notification: reminder);
        }
      }
    } catch (e) {
      print('[FCM] Error processing sync_reminders: $e');
    }
    return;
  }

  // Fallback to original logic if it's an old format
  try {
    final Map<String, dynamic> remoteData = fcmSilentData.data!;
    if (remoteData.containsKey('id') && remoteData.containsKey('scheduled_date')) {
      final reminder = ScheduledNotification(
        id: remoteData['id'],
        title: remoteData['title'],
        body: remoteData['body'],
        scheduledDate: DateTime.parse(remoteData['scheduled_date']),
        payload: remoteData['payload'],
        reminderType: _parseReminderType(remoteData['reminder_type']),
        options: (remoteData['options'] as String?)?.split(','),
        expectedAnswer: remoteData['expected_answer'],
        aiPrompt: remoteData['ai_prompt'],
        userId: remoteData['user_id'],
        createdAt: DateTime.tryParse(remoteData['created_at'] ?? ''),
        updatedAt: DateTime.tryParse(remoteData['updated_at'] ?? ''),
      );

      // Save to local cache
      await ScheduledNotificationCache().put(reminder.id, reminder);

      // Display the notification
      await NotificationService().showScheduledNotification(notification: reminder);
    }
  } catch (e) {
    print('[FCM] Error parsing old format notification: $e');
  }
}

//Needs to be a top-level function
@pragma("vm:entry-point")
Future<void> myFcmTokenHandle(String token) async {
  print('FCM Token Token Received: $token');
}

//Needs to be a top-level function
@pragma("vm:entry-point")
Future<void> myNativeTokenHandle(String token) async {
  print('Native Token Received: $token');
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