import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/viewmodels/todo_viewmodel.dart';
import 'package:to_do_list/viewmodels/reminder_page_viewmodel.dart';
import 'package:to_do_list/viewmodels/settings_viewmodel.dart';
import 'package:to_do_list/services/auth_service.dart';
import 'package:to_do_list/services/connectivity_service.dart';

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
    final connectivity = ref.watch(connectivityServiceProvider);

    // Only sync if online
    if (connectivity.currentStatus == ConnectivityStatus.online) {
      try {
        print('[DataSync] Starting initial data sync for user: ${authState?.session?.user.id}');

        final todoSyncService = ref.read(todoSyncServiceProvider);
        print('[DataSync] Starting todo sync');
        await todoSyncService.syncFromSupabase();
        print('[DataSync] Todo sync completed');

        final goalSyncService = ref.read(goalSyncServiceProvider);
        await goalSyncService.syncFromSupabase();
        print('[DataSync] Goal sync completed');

        final reminderSyncService = ref.read(reminderSyncServiceProvider);
        await reminderSyncService.syncFromSupabase();
        print('[DataSync] Reminder sync completed');

        final settingsSyncService = ref.read(settingsSyncServiceProvider);
        await settingsSyncService.syncFromSupabase();
        print('[DataSync] Settings sync completed');

        final timerPromptSyncService = ref.read(timerPromptSyncServiceProvider);
        await timerPromptSyncService.syncFromSupabase();
        print('[DataSync] Timer prompt sync completed');

        final personalitySyncService = ref.read(personalitySyncServiceProvider);
        await personalitySyncService.syncFromSupabase();
        print('[DataSync] Personality sync completed');

        final additionalInfoSyncService = ref.read(additionalInfoSyncServiceProvider);
        await additionalInfoSyncService.syncFromSupabase();
        print('[DataSync] Additional info sync completed');

        print('[DataSync] All initial data sync completed successfully');
      } catch (e) {
        print('[DataSync] Error during initial data sync: $e');
        // Re-throw to make the FutureProvider error
        rethrow;
      }
    } else {
      print('[DataSync] Offline: Skipping initial data sync, loading from local cache');
    }
  } else {
    print('[DataSync] No authenticated user, skipping sync');
  }
});

// Reminder Page View Model
final reminderPageViewModelProvider = Provider<ReminderPageViewModel>((ref) => ReminderPageViewModel(ref));

// Settings Page View Model
final settingsPageViewModelProvider = NotifierProvider<SettingsPageViewModel, SettingsPageState>(() => SettingsPageViewModel());
