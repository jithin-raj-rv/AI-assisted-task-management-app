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

final dataSyncProvider =
    NotifierProvider<DataSyncNotifier, AsyncValue<void>>(
        DataSyncNotifier.new);

class DataSyncNotifier extends Notifier<AsyncValue<void>> {
  bool _hasSynced = false;

  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> runInitialSync() async {
    if (_hasSynced) return;

    final connectivity = ref.read(connectivityServiceProvider);
    if (connectivity.currentStatus != ConnectivityStatus.online) {
      print('[DataSync] Offline, delaying sync');
      return;
    }

    state = const AsyncLoading();
    try {
      print('[DataSync] Starting initial sync');

      await ref.read(todoSyncServiceProvider).syncFromSupabase();
      await ref.read(goalSyncServiceProvider).syncFromSupabase();
      await ref.read(reminderSyncServiceProvider).syncFromSupabase();
      await ref.read(settingsSyncServiceProvider).syncFromSupabase();
      await ref.read(timerPromptSyncServiceProvider).syncFromSupabase();
      await ref.read(personalitySyncServiceProvider).syncFromSupabase();
      await ref.read(additionalInfoSyncServiceProvider).syncFromSupabase();

      _hasSynced = true;
      state = const AsyncData(null);
      print('[DataSync] Initial sync completed');
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void reset() {
    _hasSynced = false;
    state = const AsyncData(null);
  }
}

// Reminder Page View Model
final reminderPageViewModelProvider = Provider<ReminderPageViewModel>((ref) => ReminderPageViewModel(ref));

// Settings Page View Model
final settingsPageViewModelProvider = NotifierProvider<SettingsPageViewModel, SettingsPageState>(() => SettingsPageViewModel());

// Auth State Manager - handles subscriptions and sync lifecycle
class AuthStateManager extends Notifier<bool> {
  bool _isAuthenticated = false;

  @override
  bool build() {
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (authState) {
          final isNowAuthenticated = authState.session != null;
          if (isNowAuthenticated && !_isAuthenticated) {
            // Just became authenticated - setup subscriptions and sync
            _setupForAuthenticatedUser();
          } else if (!isNowAuthenticated && _isAuthenticated) {
            // Just became unauthenticated - clear subscriptions
            _clearForUnauthenticatedUser();
          }
          _isAuthenticated = isNowAuthenticated;
          state = isNowAuthenticated;
        },
        loading: () {},
        error: (error, stack) {},
      );
    });
    return false; // Initial state
  }

  void _setupForAuthenticatedUser() {
    print('[AuthStateManager] Setting up for authenticated user');

    // Trigger initial data sync first
    ref.read(dataSyncProvider.notifier).runInitialSync();

    // Then setup realtime subscriptions
    ref.read(todoSyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(goalSyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(reminderSyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(personalitySyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(additionalInfoSyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(timerPromptSyncServiceProvider).setupRealtimeSubscriptions();

    print('[AuthStateManager] Realtime subscriptions set up');
  }

  void _clearForUnauthenticatedUser() {
    print('[AuthStateManager] Clearing for unauthenticated user');

    // Reset data sync state
    ref.read(dataSyncProvider.notifier).reset();

    // Clear realtime subscriptions
    ref.read(todoSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(goalSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(reminderSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(personalitySyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(additionalInfoSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(timerPromptSyncServiceProvider).clearRealtimeSubscriptions();

    print('[AuthStateManager] Realtime subscriptions cleared');
  }
}

final authStateManagerProvider = NotifierProvider<AuthStateManager, bool>(() => AuthStateManager());
