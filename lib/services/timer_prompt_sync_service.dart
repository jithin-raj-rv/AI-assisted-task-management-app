import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/timer_prompt_cache.dart';

class TimerPromptSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final TimerPromptCache _cache = TimerPromptCache();

  List<dynamic> _activeChannels = [];

  TimerPromptSyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[TimerPromptSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final promptsData = await _supabase.from('timer_prompts').select('*').eq('user_id', user.id) as List;
      final prompts = promptsData.map((p) => TimerPrompt(
        id: p['id'],
        prompt: p['prompt'],
        scheduledTime: p['scheduled_time'] != null ? DateTime.parse(p['scheduled_time']) : DateTime.now(),
        isRecurring: p['is_recurring'] ?? false,
        weekdays: p['weekdays'] != null ? (p['weekdays'] as List<dynamic>).cast<int>() : null,
        response: p['response'],
        sent: p['sent'] ?? false,
        userId: p['user_id'],
        createdAt: p['created_at'] != null ? DateTime.parse(p['created_at']) : null,
        updatedAt: p['updated_at'] != null ? DateTime.parse(p['updated_at']) : null,
      )).toList();

      final box = await Hive.openBox<TimerPrompt>('timer_prompts');
      final newPrompts = {for (var prompt in prompts) prompt.id: prompt};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newPrompts.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        box.deleteAll(keysToDelete);
      }
      box.putAll(newPrompts);
    } catch (e) {
      print('[TimerPromptSync] Error syncing timer prompts: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final promptsChannel = _supabase.channel('timer_prompts_realtime');
    _activeChannels.add(promptsChannel);
    print('[TimerPromptSync] Setting up real-time subscription for user: ${user.id}');
    promptsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'timer_prompts',
      callback: (payload) {
        print('[TimerPromptSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete' && record != null && record['user_id'] != user.id) return;
        print('[TimerPromptSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<TimerPrompt>('timer_prompts');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[TimerPromptSync] Processing ${payload.eventType} for timer prompt id: ${record['id']}');
            print('[TimerPromptSync] Record fields: id=${record['id']}, prompt=${record['prompt']}, scheduled_time=${record['scheduled_time']}, is_recurring=${record['is_recurring']}, weekdays=${record['weekdays']}, response=${record['response']}, sent=${record['sent']}, user_id=${record['user_id']}');
            final prompt = TimerPrompt(
              id: record['id'],
              prompt: record['prompt'],
              scheduledTime: record['scheduled_time'] != null ? DateTime.parse(record['scheduled_time']) : DateTime.now(),
              isRecurring: record['is_recurring'] ?? false,
              weekdays: record['weekdays'] != null ? (record['weekdays'] as List<dynamic>).cast<int>() : null,
              response: record['response'],
              sent: record['sent'] ?? false,
              userId: record['user_id'],
              createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : null,
              updatedAt: record['updated_at'] != null ? DateTime.parse(record['updated_at']) : null,
            );
            print('[TimerPromptSync] Created timer prompt object: $prompt');
            box.put(prompt.id, prompt);
            print('[TimerPromptSync] Updated cache for timer prompt: ${prompt.id}');
            print('[TimerPromptSync] Cache now has ${box.length} items');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[TimerPromptSync] Processing DELETE for timer prompt id: ${record['id']}');
            box.delete(record['id']);
            print('[TimerPromptSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[TimerPromptSync] Error processing realtime: $e');
          print('[TimerPromptSync] Stack trace: $stack');
        }
      },
    );
    promptsChannel.subscribe();
  }

  /// Create timer prompt
  Future<void> createTimerPrompt(TimerPrompt prompt) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': prompt.id,
      'user_id': currentUser.id,
      'prompt': prompt.prompt,
      'scheduled_time': prompt.scheduledTime.toUtc().toIso8601String(),
      'is_recurring': prompt.isRecurring,
      'weekdays': prompt.weekdays,
      'response': prompt.response,
      'sent': prompt.sent,
    };

    await _supabase.from('timer_prompts').insert(supabaseData);
    await _cache.put(prompt.id, prompt);
  }

  /// Update timer prompt
  Future<void> updateTimerPrompt(String id, TimerPrompt prompt) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'prompt': prompt.prompt,
      'scheduled_time': prompt.scheduledTime.toUtc().toIso8601String(),
      'is_recurring': prompt.isRecurring,
      'weekdays': prompt.weekdays,
      'response': prompt.response,
      'sent': prompt.sent,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('timer_prompts').update(supabaseData).eq('id', id);
    await _cache.put(id, prompt);
  }

  /// Delete timer prompt
  Future<void> deleteTimerPrompt(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    await _supabase.from('timer_prompts').delete().eq('id', id);
    await _cache.delete(id);
  }
}
