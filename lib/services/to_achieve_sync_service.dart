import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/to_achieve_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/to_achieve_cache.dart';

class ToAchieveSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final ToAchieveCache _cache = ToAchieveCache();

  List<dynamic> _activeChannels = [];

  ToAchieveSyncService(this._connectivityService);

  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[ToAchieveSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase.from('to_achieves').select('*').eq('user_id', user.id) as List;
      final toAchieves = data.map((item) => ToAchieve(
        id: item['id'],
        goalId: item['goal_id'],
        title: item['title'],
        isCompleted: item['is_completed'] ?? false,
        priorityOrder: item['priority_order'] ?? 0,
        targetDate: item['target_date'] != null ? DateTime.parse(item['target_date']) : null,
      )).toList();

      final box = await Hive.openBox<ToAchieve>('to_achieves');
      final newItems = {for (var item in toAchieves) item.id!: item};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newItems.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newItems);
    } catch (e) {
      print('[ToAchieveSync] Error syncing to_achieves: $e');
    }
  }

  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final channel = _supabase.channel('to_achieves_realtime');
    _activeChannels.add(channel);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'to_achieves',
      callback: (payload) {
        final record = payload.newRecord ?? payload.oldRecord;
        if (payload.eventType.name != 'delete') {
          if (record != null && record['user_id'] != user.id) {
            return;
          }
        }
        try {
          final box = Hive.box<ToAchieve>('to_achieves');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            final toAchieve = ToAchieve(
              id: record['id'],
              goalId: record['goal_id'],
              title: record['title'],
              isCompleted: record['is_completed'] ?? false,
              priorityOrder: record['priority_order'] ?? 0,
              targetDate: record['target_date'] != null ? DateTime.parse(record['target_date']) : null,
            );
            box.put(toAchieve.id!, toAchieve);
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            box.delete(record['id']);
          }
        } catch (e) {
          print('[ToAchieveSync] Error processing realtime: $e');
        }
      },
    );
    channel.subscribe();
  }

  Future<void> createToAchieve(ToAchieve toAchieve) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': toAchieve.id,
      'user_id': currentUser.id,
      'goal_id': toAchieve.goalId,
      'title': toAchieve.title,
      'is_completed': toAchieve.isCompleted,
      'priority_order': toAchieve.priorityOrder,
      'target_date': toAchieve.targetDate?.toIso8601String(),
    };

    await _supabase.from('to_achieves').insert(supabaseData);
    await _cache.put(toAchieve.id!, toAchieve);
  }

  Future<void> updateToAchieve(String id, ToAchieve toAchieve) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'title': toAchieve.title,
      'is_completed': toAchieve.isCompleted,
      'priority_order': toAchieve.priorityOrder,
      'target_date': toAchieve.targetDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('to_achieves').update(supabaseData).eq('id', id);
    await _cache.put(id, toAchieve);
  }

  Future<void> deleteToAchieve(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('to_achieves').delete().eq('id', id);
    await _cache.delete(id);
  }

  Future<List<ToAchieve>> getToAchieves(String goalId) async {
    final all = await _cache.getAll();
    final filtered = all.where((t) => t.goalId == goalId).toList();
    filtered.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
    return filtered;
  }

  Future<void> reorderToAchieves(String goalId, List<ToAchieve> toAchieves) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    for (int i = 0; i < toAchieves.length; i++) {
      toAchieves[i].priorityOrder = i;
      await updateToAchieve(toAchieves[i].id!, toAchieves[i]);
    }
  }
}
