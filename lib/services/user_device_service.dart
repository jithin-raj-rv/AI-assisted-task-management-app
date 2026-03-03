import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';

class UserDeviceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;

  UserDeviceService(this._connectivityService);

  /// Update the is_scheduled status for the current user's device identified by fcmToken
  Future<void> updateScheduledStatus(String fcmToken, bool isScheduled) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      print('[UserDeviceService] Cannot update scheduled status while offline');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[UserDeviceService] User is not authenticated');
      return;
    }

    try {
      await _supabase
          .from('user_devices')
          .update({'is_scheduled': isScheduled, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken);

      print('[UserDeviceService] Updated is_scheduled to $isScheduled for device $fcmToken of user ${user.id}');
    } catch (e) {
      print('[UserDeviceService] Error updating scheduled status for device $fcmToken: $e');
    }
  }

  /// Update the is_sent status for a specific user device identified by fcmToken.
  Future<void> updateSentStatus(String fcmToken, bool isSent) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      print('[UserDeviceService] Cannot update sent status while offline');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[UserDeviceService] User is not authenticated');
      return;
    }

    try {
      await _supabase
          .from('user_devices')
          .update({'is_sent': isSent, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken);

      print('[UserDeviceService] Updated is_sent to $isSent for device $fcmToken of user ${user.id}');
    } catch (e) {
      print('[UserDeviceService] Error updating sent status for device $fcmToken: $e');
    }
  }

  /// Set is_scheduled to true for the current user's device (identified by FCM token)
  Future<void> markAsScheduled() async {
    final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await updateScheduledStatus(fcmToken, true);
    } else {
      print('[UserDeviceService] Could not get FCM token, cannot mark as scheduled.');
    }
  }

  /// Set is_scheduled to false for the current user's device (identified by FCM token)
  Future<void> markAsNotScheduled() async {
    final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await updateScheduledStatus(fcmToken, false);
    }
  }

  /// Set both is_scheduled and is_sent to false to trigger the queue processing
  Future<void> triggerQueueProcessing() async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      print('[UserDeviceService] Cannot trigger queue while offline');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[UserDeviceService] User is not authenticated');
      return;
    }

    try {
      final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('[UserDeviceService] Could not get FCM token, cannot trigger queue.');
        return;
      }

      // Setting both to false triggers the 30-second pgmq wait process
      await _supabase
          .from('user_devices')
          .update({'is_scheduled': false, 'is_sent': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken);

      print('[UserDeviceService] Triggered queue processing for device $fcmToken of user ${user.id}');
    } catch (e) {
      print('[UserDeviceService] Error triggering queue: $e');
    }
  }

  /// Set is_sent to true for the current user's device (identified by FCM token)
  Future<void> markAsSent() async {
    final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await updateSentStatus(fcmToken, true);
    } else {
      print('[UserDeviceService] Could not get FCM token, cannot mark as sent.');
    }
  }

  /// Set is_sent to false for the current user's device (identified by FCM token)
  Future<void> markAsNotSent() async {
    final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await updateSentStatus(fcmToken, false);
    } else {
      print('[UserDeviceService] Could not get FCM token, cannot mark as not sent.');
    }
  }

  /// Get the current scheduled status for the current user's device (identified by FCM token)
  Future<bool?> getScheduledStatus() async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      return null;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final fcmToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('[UserDeviceService] Could not get FCM token, cannot retrieve scheduled status.');
        return null;
      }

      final deviceResponse = await _supabase
          .from('user_devices')
          .select('is_scheduled')
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken)
          .single();

      return deviceResponse?['is_scheduled'] as bool?;
    } catch (e) {
      print('[UserDeviceService] Error getting scheduled status: $e');
      return null;
    }
  }
}