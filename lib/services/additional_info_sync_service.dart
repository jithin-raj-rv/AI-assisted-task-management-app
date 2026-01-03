import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/additional_info_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/additional_info_cache.dart';

class AdditionalInfoSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final AdditionalInfoCache _cache = AdditionalInfoCache();

  List<dynamic> _activeChannels = [];

  AdditionalInfoSyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[AdditionalInfoSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final infoData = await _supabase.from('additional_info').select('*').eq('user_id', user.id) as List;
      final infoItems = infoData.map((i) => AdditionalInfo.fromJson(i)).toList();

      final box = await Hive.openBox<AdditionalInfo>('additional_info_items');
      final newInfoItems = {for (var info in infoItems) info.id!: info};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newInfoItems.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newInfoItems);
    } catch (e) {
      print('[AdditionalInfoSync] Error syncing additional info: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[AdditionalInfoSync] No user logged in, skipping realtime setup');
      return;
    }

    clearRealtimeSubscriptions();

    final infoChannel = _supabase.channel('additional_info_realtime_${user.id}');
    _activeChannels.add(infoChannel);
    print('[AdditionalInfoSync] Setting up real-time subscription for user: ${user.id}');

    infoChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'additional_info',
      callback: (payload) {
        print('[AdditionalInfoSync] ===== REAL-TIME EVENT RECEIVED =====');
        print('[AdditionalInfoSync] Event Type: ${payload.eventType}');
        print('[AdditionalInfoSync] Table: ${payload.table}');
        print('[AdditionalInfoSync] New Record: ${payload.newRecord}');
        print('[AdditionalInfoSync] Old Record: ${payload.oldRecord}');

        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete') {
          print('[AdditionalInfoSync] Checking user ID match - Current user: ${user.id}, Record user_id: ${record?['user_id']}');
          if (record != null && record['user_id'] != user.id) {
            print('[AdditionalInfoSync] User ID mismatch, skipping event');
            return;
          }
        }

        try {
          final box = Hive.box<AdditionalInfo>('additional_info_items');
          print('[AdditionalInfoSync] Hive box opened, current items: ${box.length}');

          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[AdditionalInfoSync] Processing ${payload.eventType.name.toUpperCase()} for info id: ${record['id']}');
            final info = AdditionalInfo.fromJson(record);
            print('[AdditionalInfoSync] Created info object: ${info.info} (id: ${info.id})');
            box.put(info.id!, info);
            print('[AdditionalInfoSync] Cache updated successfully. Total items now: ${box.length}');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[AdditionalInfoSync] Processing DELETE for info id: ${record['id']}');
            box.delete(record['id']);
            print('[AdditionalInfoSync] Cache deletion successful. Total items now: ${box.length}');
          } else {
            print('[AdditionalInfoSync] Unknown event type: ${payload.eventType.name}');
          }
          print('[AdditionalInfoSync] ===== EVENT PROCESSING COMPLETE =====');
        } catch (e, stack) {
          print('[AdditionalInfoSync] ERROR processing realtime event: $e');
          print('[AdditionalInfoSync] Stack trace: $stack');
        }
      },
    );

    print('[AdditionalInfoSync] Calling subscribe() on channel');
    infoChannel.subscribe();
    print('[AdditionalInfoSync] subscribe() called - realtime setup complete');
  }

  /// Create additional info
  Future<void> createInfo(AdditionalInfo info) async {
    print('[AdditionalInfoSync] ===== CREATING INFO =====');
    print('[AdditionalInfoSync] Info: ${info.info}');
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = info.toJson()
      ..['user_id'] = currentUser.id
      ..remove('id'); // Remove id so Supabase generates it

    final response = await _supabase.from('additional_info').insert(supabaseData).select().single();
    final createdInfo = AdditionalInfo.fromJson(response);
    await _cache.put(createdInfo.id!, createdInfo);
    print('[AdditionalInfoSync] Info created successfully with ID: ${createdInfo.id}');
  }

  /// Update additional info
  Future<void> updateInfo(String id, AdditionalInfo info) async {
    print('[AdditionalInfoSync] ===== UPDATING INFO =====');
    print('[AdditionalInfoSync] Info ID: $id');
    print('[AdditionalInfoSync] New info: ${info.info}');
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = info.toJson()
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('additional_info').update(supabaseData).eq('id', id);
    await _cache.put(id, info);
    print('[AdditionalInfoSync] Info updated successfully');
  }

  /// Delete additional info
  Future<void> deleteInfo(String id) async {
    print('[AdditionalInfoSync] ===== DELETING INFO =====');
    print('[AdditionalInfoSync] Info ID: $id');
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('additional_info').delete().eq('id', id);
    await _cache.delete(id);
    print('[AdditionalInfoSync] Info deleted successfully');
  }
}
