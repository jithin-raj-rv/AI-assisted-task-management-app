import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/goal_cache.dart';

class GoalSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final GoalCache _cache = GoalCache();

  List<dynamic> _activeChannels = [];

  GoalSyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[GoalSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final goalsData = await _supabase.from('goals').select('*').eq('user_id', user.id) as List;
      final goals = goalsData.map((g) => Goal(
        id: g['id'],
        title: g['title'],
        description: g['description'] ?? '',
        targetDate: g['target_date'] != null ? DateTime.parse(g['target_date']) : DateTime.now(),
        isCompleted: g['is_completed'] ?? false,
        userId: g['user_id'],
        createdAt: g['created_at'] != null ? DateTime.parse(g['created_at']) : null,
        updatedAt: g['updated_at'] != null ? DateTime.parse(g['updated_at']) : null,
      )).toList();

      final box = await Hive.openBox<Goal>('goals');
      final newGoals = {for (var goal in goals) goal.id!: goal};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newGoals.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newGoals);
    } catch (e) {
      print('[GoalSync] Error syncing goals: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final goalsChannel = _supabase.channel('goals_realtime');
    _activeChannels.add(goalsChannel);
    print('[GoalSync] Setting up real-time subscription for user: ${user.id}');
    goalsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'goals',
      callback: (payload) {
        print('[GoalSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete') {
          print('[GoalSync] user.id: ${user?.id}, record user_id: ${record?['user_id']}');
          if (record != null && record['user_id'] != user.id) {
            print('[GoalSync] User ID mismatch, skipping event');
            return;
          }
        }
        print('[GoalSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<Goal>('goals');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[GoalSync] Processing ${payload.eventType} for goal id: ${record['id']}');
            print('[GoalSync] Record fields: id=${record['id']}, title=${record['title']}, description=${record['description']}, target_date=${record['target_date']}, is_completed=${record['is_completed']}, user_id=${record['user_id']}');
            final goal = Goal(
              id: record['id'],
              title: record['title'],
              description: record['description'] ?? '',
              targetDate: record['target_date'] != null ? DateTime.parse(record['target_date']) : DateTime.now(),
              isCompleted: record['is_completed'] ?? false,
              userId: record['user_id'],
              createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : null,
              updatedAt: record['updated_at'] != null ? DateTime.parse(record['updated_at']) : null,
            );
            print('[GoalSync] Created goal object: $goal');
            box.put(goal.id!, goal);
            print('[GoalSync] Updated cache for goal: ${goal.id}');
            print('[GoalSync] Cache now has ${box.length} items');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[GoalSync] Processing DELETE for goal id: ${record['id']}');
            box.delete(record['id']);
            print('[GoalSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[GoalSync] Error processing realtime: $e');
          print('[GoalSync] Stack trace: $stack');
        }
      },
    );
    goalsChannel.subscribe();
  }

  /// Create goal
  Future<void> createGoal(Goal goal) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': goal.id,
      'user_id': currentUser.id,
      'title': goal.title,
      'description': goal.description,
      'target_date': goal.targetDate.toIso8601String(),
      'is_completed': goal.isCompleted,
    };

    await _supabase.from('goals').insert(supabaseData);
    await _cache.put(goal.id!, goal);
  }

  /// Update goal
  Future<void> updateGoal(String id, Goal goal) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'title': goal.title,
      'description': goal.description,
      'target_date': goal.targetDate.toIso8601String(),
      'is_completed': goal.isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('goals').update(supabaseData).eq('id', id);
    await _cache.put(id, goal);
  }

  /// Delete goal
  Future<void> deleteGoal(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('goals').delete().eq('id', id);
    await _cache.delete(id);
  }
}
