import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/viewmodels/todo_viewmodel.dart';
import 'package:to_do_list/viewmodels/reminder_page_viewmodel.dart';
import 'package:to_do_list/viewmodels/settings_viewmodel.dart';
import 'package:to_do_list/viewmodels/goals_viewmodel.dart';
import 'package:to_do_list/viewmodels/scheduled_notifications_viewmodel.dart';
import 'package:to_do_list/services/auth_service.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/services/foreground_service_manager.dart';

export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:to_do_list/services/foreground_service_manager.dart';

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
    // Listen for connectivity changes to retry sync when coming online
    final connectivity = ref.read(connectivityServiceProvider);
    connectivity.status.listen((status) {
      if (status == ConnectivityStatus.offline) {
        // Reset sync flag when going offline so it will re-sync when back online
        _hasSynced = false;
        print('[DataSync] Connectivity changed to offline, resetting sync flag');
      } else if (status == ConnectivityStatus.online && !_hasSynced) {
        print('[DataSync] Connectivity changed to online, retrying sync');
        runInitialSync();
      }
    });
    return const AsyncData(null);
  }

  Future<void> runInitialSync({bool force = false}) async {
    if (_hasSynced && !force) return;

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
      await ref.read(goalStepSyncServiceProvider).syncFromSupabase();
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

// Check if all viewmodels are ready (finished loading from cache)
final allViewModelsReadyProvider = Provider<bool>((ref) {
  final todoState = ref.watch(todoViewModelProvider);
  final goalState = ref.watch(goalsPageViewModelProvider);
  final reminderState = ref.watch(scheduledNotificationsViewModelProvider);

  final allReady = !todoState.isLoading && !goalState.isLoading && !reminderState.isLoading;
  print("allViewModelsReady: todos=${!todoState.isLoading}, goals=${!goalState.isLoading}, reminders=${!reminderState.isLoading}, total=$allReady");
  return allReady;
});

// Simple boolean provider for whether user has data
final userHasDataProvider = Provider<bool>((ref) {
  final todoState = ref.watch(todoViewModelProvider);
  final goalState = ref.watch(goalsPageViewModelProvider);
  final reminderState = ref.watch(scheduledNotificationsViewModelProvider);

  // Check if any cache has data
  final hasTodos = todoState.todos.isNotEmpty;
  final hasGoals = goalState.goals.isNotEmpty;
  final hasReminders = reminderState.notifications.isNotEmpty;

  final hasData = hasTodos || hasGoals || hasReminders;
  print("userHasDataProvider: todos=${todoState.todos.length}, goals=${goalState.goals.length}, reminders=${reminderState.notifications.length}, hasData=$hasData");
  return hasData;
});

// Auth State Manager - handles subscriptions and sync lifecycle
class AuthStateManager extends Notifier<bool> {
  bool _isAuthenticated = false;
  bool _hasCheckedExistingSession = false;

  @override
  bool build() {
    // Check for existing session on startup - this handles the case where
    // the app is reopened with an existing session that was restored before
    // Riverpod providers were initialized
    if (!_hasCheckedExistingSession) {
      _hasCheckedExistingSession = true;
      _checkExistingSession();
    }

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

  /// Check for existing session on startup - handles app restart scenario
  /// where session is restored before Riverpod providers are initialized
  void _checkExistingSession() {
    final auth = ref.read(authServiceProvider);
    final currentUser = auth.currentUser;
    
    if (currentUser != null) {
      print('[AuthStateManager] Found existing session on startup for user: ${currentUser.id}');
      _isAuthenticated = true;
      state = true;
      _setupForAuthenticatedUser();
    } else {
      print('[AuthStateManager] No existing session on startup');
    }
  }

  void _setupForAuthenticatedUser() {
    print('[AuthStateManager] Setting up for authenticated user');

    // Trigger initial data sync first
    ref.read(dataSyncProvider.notifier).runInitialSync();

    // Then setup realtime subscriptions
    ref.read(todoSyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(goalSyncServiceProvider).setupRealtimeSubscriptions();
    ref.read(goalStepSyncServiceProvider).setupRealtimeSubscriptions();
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
    ref.read(goalStepSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(reminderSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(personalitySyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(additionalInfoSyncServiceProvider).clearRealtimeSubscriptions();
    ref.read(timerPromptSyncServiceProvider).clearRealtimeSubscriptions();

    print('[AuthStateManager] Realtime subscriptions cleared');
  }
}

final authStateManagerProvider = NotifierProvider<AuthStateManager, bool>(() => AuthStateManager());
