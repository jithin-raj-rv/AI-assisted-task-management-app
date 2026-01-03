import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/personality_trait_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/personality_cache.dart';

class PersonalitySyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final PersonalityCache _cache = PersonalityCache();

  List<dynamic> _activeChannels = [];

  PersonalitySyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[PersonalitySync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final traitsData = await _supabase.from('personality_traits').select('*').eq('user_id', user.id) as List;
      final traits = traitsData.map((t) => PersonalityTrait.fromJson(t)).toList();

      final box = await Hive.openBox<PersonalityTrait>('personality_traits');
      final newTraits = {for (var trait in traits) trait.id!: trait};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newTraits.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newTraits);
    } catch (e) {
      print('[PersonalitySync] Error syncing personality traits: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[PersonalitySync] No user logged in, skipping realtime setup');
      return;
    }

    clearRealtimeSubscriptions();

    final traitsChannel = _supabase.channel('personality_traits_realtime_${user.id}');
    _activeChannels.add(traitsChannel);
    print('[PersonalitySync] Setting up real-time subscription for user: ${user.id}');

    traitsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'personality_traits',
      callback: (payload) {
        print('[PersonalitySync] ===== REAL-TIME EVENT RECEIVED =====');
        print('[PersonalitySync] Event Type: ${payload.eventType}');
        print('[PersonalitySync] Table: ${payload.table}');
        print('[PersonalitySync] New Record: ${payload.newRecord}');
        print('[PersonalitySync] Old Record: ${payload.oldRecord}');

        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete') {
          print('[PersonalitySync] Checking user ID match - Current user: ${user.id}, Record user_id: ${record?['user_id']}');
          if (record != null && record['user_id'] != user.id) {
            print('[PersonalitySync] User ID mismatch, skipping event');
            return;
          }
        }

        try {
          final box = Hive.box<PersonalityTrait>('personality_traits');
          print('[PersonalitySync] Hive box opened, current items: ${box.length}');

          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[PersonalitySync] Processing ${payload.eventType.name.toUpperCase()} for trait id: ${record['id']}');
            final trait = PersonalityTrait.fromJson(record);
            print('[PersonalitySync] Created trait object: ${trait.trait} (id: ${trait.id})');
            box.put(trait.id!, trait);
            print('[PersonalitySync] Cache updated successfully. Total items now: ${box.length}');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[PersonalitySync] Processing DELETE for trait id: ${record['id']}');
            box.delete(record['id']);
            print('[PersonalitySync] Cache deletion successful. Total items now: ${box.length}');
          } else {
            print('[PersonalitySync] Unknown event type: ${payload.eventType.name}');
          }
          print('[PersonalitySync] ===== EVENT PROCESSING COMPLETE =====');
        } catch (e, stack) {
          print('[PersonalitySync] ERROR processing realtime event: $e');
          print('[PersonalitySync] Stack trace: $stack');
        }
      },
    );

    print('[PersonalitySync] Calling subscribe() on channel');
    traitsChannel.subscribe();
    print('[PersonalitySync] subscribe() called - realtime setup complete');
  }

  /// Create personality trait
  Future<void> createTrait(PersonalityTrait trait) async {
    print('[PersonalitySync] ===== CREATING TRAIT =====');
    print('[PersonalitySync] Trait: ${trait.trait}');
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = trait.toJson()
      ..['user_id'] = currentUser.id
      ..remove('id'); // Remove id so Supabase generates it

    final response = await _supabase.from('personality_traits').insert(supabaseData).select().single();
    final createdTrait = PersonalityTrait.fromJson(response);
    await _cache.put(createdTrait.id!, createdTrait);
    print('[PersonalitySync] Trait created successfully with ID: ${createdTrait.id}');
  }

  /// Update personality trait
  Future<void> updateTrait(String id, PersonalityTrait trait) async {
    print('[PersonalitySync] ===== UPDATING TRAIT =====');
    print('[PersonalitySync] Trait ID: $id');
    print('[PersonalitySync] New trait: ${trait.trait}');
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = trait.toJson()
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('personality_traits').update(supabaseData).eq('id', id);
    await _cache.put(id, trait);
    print('[PersonalitySync] Trait updated successfully');
  }

  /// Delete personality trait
  Future<void> deleteTrait(String id) async {
    print('[PersonalitySync] ===== DELETING TRAIT =====');
    print('[PersonalitySync] Trait ID: $id');
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('personality_traits').delete().eq('id', id);
    await _cache.delete(id);
    print('[PersonalitySync] Trait deleted successfully');
  }
}
