import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/viewmodels/todo_viewmodel.dart';
import 'package:to_do_list/viewmodels/reminder_page_viewmodel.dart';
import 'package:to_do_list/viewmodels/settings_viewmodel.dart';
import 'package:to_do_list/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());



// Auth Providers
final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.read(authServiceProvider);
  return auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.read(authServiceProvider);
  return auth.currentUser;
});

// Sync Provider - triggers sync when user becomes authenticated
final dataSyncProvider = FutureProvider<void>((ref) async {
  final authStateAsync = ref.watch(authStateProvider);

  // Wait for auth state to be available
  final authState = authStateAsync.asData?.value;

  if (authState?.session?.user != null) {
    try {
      final todoSyncService = ref.read(todoSyncServiceProvider);
      await todoSyncService.syncFromSupabase();
      print('Initial todo data sync completed successfully');

      final goalSyncService = ref.read(goalSyncServiceProvider);
      await goalSyncService.syncFromSupabase();
      print('Initial goal data sync completed successfully');

      final reminderSyncService = ref.read(reminderSyncServiceProvider);
      await reminderSyncService.syncFromSupabase();
      print('Initial reminder data sync completed successfully');

      final settingsSyncService = ref.read(settingsSyncServiceProvider);
      await settingsSyncService.syncFromSupabase();
      print('Initial settings data sync completed successfully');

      final timerPromptSyncService = ref.read(timerPromptSyncServiceProvider);
      await timerPromptSyncService.syncFromSupabase();
      print('Initial timer prompt data sync completed successfully');

      final personalitySyncService = ref.read(personalitySyncServiceProvider);
      await personalitySyncService.syncFromSupabase();
      print('Initial personality data sync completed successfully');

      final additionalInfoSyncService = ref.read(additionalInfoSyncServiceProvider);
      await additionalInfoSyncService.syncFromSupabase();
      print('Initial additional info data sync completed successfully');
    } catch (e) {
      print('Error during initial data sync: $e');
      // Re-throw to make the FutureProvider error
      rethrow;
    }
  }
});

// Reminder Page View Model
final reminderPageViewModelProvider = Provider<ReminderPageViewModel>((ref) => ReminderPageViewModel(ref));

// Settings Page View Model
final settingsPageViewModelProvider = NotifierProvider<SettingsPageViewModel, SettingsPageState>(() => SettingsPageViewModel());
