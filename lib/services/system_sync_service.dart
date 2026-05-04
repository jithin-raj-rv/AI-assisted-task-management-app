import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/system_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/system_cache.dart';

class SystemSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final SystemCache _cache = SystemCache();

  List<dynamic> _activeChannels = [];

  SystemSyncService(this._connectivityService);

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
      final systemsData = await _supabase.from('systems').select('*').eq('user_id', user.id) as List;
      final systems = systemsData.map((s) => System(
        id: s['id'],
        goalId: s['goal_id'],
        systemName: s['system_name'],
        isCompleted: s['is_completed'] ?? false,
        priorityOrder: s['priority_order'] ?? 0,
        userId: s['user_id'],
        createdAt: s['created_at'] != null ? DateTime.parse(s['created_at']) : null,
        updatedAt: s['updated_at'] != null ? DateTime.parse(s['updated_at']) : null,
      )).toList();

      final box = await Hive.openBox<System>('systems');
      final newSystems = {for (var system in systems) system.id!: system};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newSystems.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newSystems);
    } catch (e) {
      print('[GoalStepSync] Error syncing goal steps: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final systemsChannel = _supabase.channel('systems_realtime');
    _activeChannels.add(systemsChannel);
    print('[SystemSync] Setting up real-time subscription for user: ${user.id}');
    systemsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'systems',
      callback: (payload) {
        print('[SystemSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete') {
          print('[SystemSync] user.id: ${user?.id}, record user_id: ${record?['user_id']}');
          if (record != null && record['user_id'] != user.id) {
            print('[SystemSync] User ID mismatch, skipping event');
            return;
          }
        }
        print('[SystemSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<System>('systems');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[SystemSync] Processing ${payload.eventType} for system id: ${record['id']}');
            print('[SystemSync] Record fields: id=${record['id']}, goal_id=${record['goal_id']}, system_name=${record['system_name']}, is_completed=${record['is_completed']}, priority_order=${record['priority_order']}, user_id=${record['user_id']}');
            final system = System(
              id: record['id'],
              goalId: record['goal_id'],
              systemName: record['system_name'],
              isCompleted: record['is_completed'] ?? false,
              priorityOrder: record['priority_order'] ?? 0,
              userId: record['user_id'],
              createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : null,
              updatedAt: record['updated_at'] != null ? DateTime.parse(record['updated_at']) : null,
            );
            print('[SystemSync] Created system object: $system');
            box.put(system.id!, system);
            print('[SystemSync] Updated cache for system: ${system.id}');
            print('[SystemSync] Cache now has ${box.length} items');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[SystemSync] Processing DELETE for system id: ${record['id']}');
            box.delete(record['id']);
            print('[SystemSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[SystemSync] Error processing realtime: $e');
          print('[SystemSync] Stack trace: $stack');
        }
      },
    );
    systemsChannel.subscribe();
  }

  /// Create system
  Future<void> createSystem(System system) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': system.id,
      'goal_id': system.goalId,
      'user_id': currentUser.id,
      'system_name': system.systemName,
      'is_completed': system.isCompleted,
      'priority_order': system.priorityOrder,
    };

    await _supabase.from('systems').insert(supabaseData);
    await _cache.put(system.id!, system);
  }

  /// Update system
  Future<void> updateSystem(String id, System system) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'system_name': system.systemName,
      'is_completed': system.isCompleted,
      'priority_order': system.priorityOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('systems').update(supabaseData).eq('id', id);
    await _cache.put(id, system);
  }

  /// Delete system
  Future<void> deleteSystem(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('systems').delete().eq('id', id);
    await _cache.delete(id);
  }

  /// Reorder systems
  Future<void> reorderSystems(String goalId, List<System> systems) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    // Update priority order for each system
    for (int i = 0; i < systems.length; i++) {
      final system = systems[i];
      final supabaseData = {
        'priority_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('systems').update(supabaseData).eq('id', system.id!);
      await _cache.put(system.id!, system);
    }
  }

  /// Get systems for a specific goal
  Future<List<System>> getSystems(String goalId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final systemsData = await _supabase
          .from('systems')
          .select('*')
          .eq('goal_id', goalId)
          .eq('user_id', user.id)
          .order('priority_order', ascending: true) as List;

      final systems = systemsData.map((s) => System(
        id: s['id'],
        goalId: s['goal_id'],
        systemName: s['system_name'],
        isCompleted: s['is_completed'] ?? false,
        priorityOrder: s['priority_order'] ?? 0,
        userId: s['user_id'],
        createdAt: s['created_at'] != null ? DateTime.parse(s['created_at']) : null,
        updatedAt: s['updated_at'] != null ? DateTime.parse(s['updated_at']) : null,
      )).toList();

      return systems;
    } catch (e) {
      print('[SystemSync] Error fetching systems: $e');
      return [];
    }
  }

  /// Get a specific system by ID
  Future<System?> getSystemById(String id) async {
    return await _cache.get(id);
  }
}