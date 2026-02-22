import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/goal_step_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/goal_step_cache.dart';

class GoalStepSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final GoalStepCache _cache = GoalStepCache();

  List<dynamic> _activeChannels = [];

  GoalStepSyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[GoalStepSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final stepsData = await _supabase.from('goal_steps').select('*').eq('user_id', user.id) as List;
      final steps = stepsData.map((s) => GoalStep(
        id: s['id'],
        goalId: s['goal_id'],
        stepText: s['step_text'],
        isCompleted: s['is_completed'] ?? false,
        sortOrder: s['sort_order'] ?? 0,
        userId: s['user_id'],
        createdAt: s['created_at'] != null ? DateTime.parse(s['created_at']) : null,
        updatedAt: s['updated_at'] != null ? DateTime.parse(s['updated_at']) : null,
      )).toList();

      final box = await Hive.openBox<GoalStep>('goal_steps');
      final newSteps = {for (var step in steps) step.id!: step};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newSteps.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newSteps);
    } catch (e) {
      print('[GoalStepSync] Error syncing goal steps: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final stepsChannel = _supabase.channel('goal_steps_realtime');
    _activeChannels.add(stepsChannel);
    print('[GoalStepSync] Setting up real-time subscription for user: ${user.id}');
    stepsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'goal_steps',
      callback: (payload) {
        print('[GoalStepSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete') {
          print('[GoalStepSync] user.id: ${user?.id}, record user_id: ${record?['user_id']}');
          if (record != null && record['user_id'] != user.id) {
            print('[GoalStepSync] User ID mismatch, skipping event');
            return;
          }
        }
        print('[GoalStepSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<GoalStep>('goal_steps');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[GoalStepSync] Processing ${payload.eventType} for goal step id: ${record['id']}');
            print('[GoalStepSync] Record fields: id=${record['id']}, goal_id=${record['goal_id']}, step_text=${record['step_text']}, is_completed=${record['is_completed']}, sort_order=${record['sort_order']}, user_id=${record['user_id']}');
            final step = GoalStep(
              id: record['id'],
              goalId: record['goal_id'],
              stepText: record['step_text'],
              isCompleted: record['is_completed'] ?? false,
              sortOrder: record['sort_order'] ?? 0,
              userId: record['user_id'],
              createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : null,
              updatedAt: record['updated_at'] != null ? DateTime.parse(record['updated_at']) : null,
            );
            print('[GoalStepSync] Created goal step object: $step');
            box.put(step.id!, step);
            print('[GoalStepSync] Updated cache for goal step: ${step.id}');
            print('[GoalStepSync] Cache now has ${box.length} items');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[GoalStepSync] Processing DELETE for goal step id: ${record['id']}');
            box.delete(record['id']);
            print('[GoalStepSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[GoalStepSync] Error processing realtime: $e');
          print('[GoalStepSync] Stack trace: $stack');
        }
      },
    );
    stepsChannel.subscribe();
  }

  /// Create goal step
  Future<void> createGoalStep(GoalStep goalStep) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': goalStep.id,
      'goal_id': goalStep.goalId,
      'user_id': currentUser.id,
      'step_text': goalStep.stepText,
      'is_completed': goalStep.isCompleted,
      'sort_order': goalStep.sortOrder,
    };

    await _supabase.from('goal_steps').insert(supabaseData);
    await _cache.put(goalStep.id!, goalStep);
  }

  /// Update goal step
  Future<void> updateGoalStep(String id, GoalStep goalStep) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'step_text': goalStep.stepText,
      'is_completed': goalStep.isCompleted,
      'sort_order': goalStep.sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('goal_steps').update(supabaseData).eq('id', id);
    await _cache.put(id, goalStep);
  }

  /// Delete goal step
  Future<void> deleteGoalStep(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('goal_steps').delete().eq('id', id);
    await _cache.delete(id);
  }

  /// Reorder goal steps
  Future<void> reorderGoalSteps(String goalId, List<GoalStep> steps) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    // Update sort order for each step
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final supabaseData = {
        'sort_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('goal_steps').update(supabaseData).eq('id', step.id!);
      await _cache.put(step.id!, step);
    }
  }

  /// Get goal steps for a specific goal
  Future<List<GoalStep>> getGoalSteps(String goalId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final stepsData = await _supabase
          .from('goal_steps')
          .select('*')
          .eq('goal_id', goalId)
          .eq('user_id', user.id)
          .order('sort_order', ascending: true) as List;

      final steps = stepsData.map((s) => GoalStep(
        id: s['id'],
        goalId: s['goal_id'],
        stepText: s['step_text'],
        isCompleted: s['is_completed'] ?? false,
        sortOrder: s['sort_order'] ?? 0,
        userId: s['user_id'],
        createdAt: s['created_at'] != null ? DateTime.parse(s['created_at']) : null,
        updatedAt: s['updated_at'] != null ? DateTime.parse(s['updated_at']) : null,
      )).toList();

      return steps;
    } catch (e) {
      print('[GoalStepSync] Error fetching goal steps: $e');
      return [];
    }
  }

  /// Get a specific goal step by ID
  Future<GoalStep?> getGoalStepById(String id) async {
    return await _cache.get(id);
  }
}