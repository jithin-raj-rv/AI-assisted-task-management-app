import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/cache/additional_info_cache.dart';
import 'package:to_do_list/cache/goal_cache.dart';
import 'package:to_do_list/cache/personality_cache.dart';
import 'package:to_do_list/cache/scheduled_notification_cache.dart';
import 'package:to_do_list/cache/settings_cache.dart';
import 'package:to_do_list/cache/timer_prompt_cache.dart';
import 'package:to_do_list/cache/todo_cache.dart';
import 'package:to_do_list/cache/user_feedback_cache.dart';
import 'package:to_do_list/services/additional_info_sync_service.dart';
import 'package:to_do_list/services/goal_sync_service.dart';
import 'package:to_do_list/services/personality_sync_service.dart';
import 'package:to_do_list/services/reminder_sync_service.dart';
import 'package:to_do_list/services/settings_sync_service.dart';
import 'package:to_do_list/services/timer_prompt_sync_service.dart';
import 'package:to_do_list/services/todo_sync_service.dart';
import 'package:to_do_list/services/connectivity_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);

    // After successful sign in, sync data from Supabase to cache
    final connectivityService = ConnectivityService();

    if (connectivityService.currentStatus == ConnectivityStatus.online) {
      final todoSyncService = TodoSyncService(connectivityService);
      await todoSyncService.syncFromSupabase();

      final goalSyncService = GoalSyncService(connectivityService);
      await goalSyncService.syncFromSupabase();

      final reminderSyncService = ReminderSyncService(connectivityService);
      await reminderSyncService.syncFromSupabase();

      final settingsSyncService = SettingsSyncService(connectivityService);
      await settingsSyncService.syncFromSupabase();

      final timerPromptSyncService = TimerPromptSyncService(connectivityService);
      await timerPromptSyncService.syncFromSupabase();

      final personalitySyncService = PersonalitySyncService(connectivityService);
      await personalitySyncService.syncFromSupabase();

      final additionalInfoSyncService = AdditionalInfoSyncService(connectivityService);
      await additionalInfoSyncService.syncFromSupabase();
    }
  }

  Future<void> signOut() async {
    // Clear all caches before signing out
    await AdditionalInfoCache().clear();
    await GoalCache().clear();
    await PersonalityCache().clear();
    await ScheduledNotificationCache().clear();
    await SettingsCache().clear();
    await TimerPromptCache().clear();
    await TodoCache().clear();
    await UserFeedbackCache().clear();

    await _supabase.auth.signOut();
  }

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;
}
