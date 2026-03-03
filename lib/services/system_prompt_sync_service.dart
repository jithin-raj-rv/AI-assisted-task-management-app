import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/system_prompt_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/system_prompt_cache.dart';

class SystemPromptSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final SystemPromptCache _cache = SystemPromptCache();

  List<dynamic> _activeChannels = [];

  SystemPromptSyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[SystemPromptSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    print('[SystemPromptSync] Starting syncFromSupabase, user: ${user?.id}');
    if (user == null) {
      print('[SystemPromptSync] User is null, skipping sync');
      return;
    }

    try {
      print('[SystemPromptSync] Fetching system prompts from Supabase for user: ${user.id}');
      final promptsData = await _supabase.from('system_prompts').select('*').eq('user_id', user.id) as List;
      print('[SystemPromptSync] Fetched ${promptsData.length} raw system prompts from Supabase');
      
      if (promptsData.isEmpty) {
        print('[SystemPromptSync] No system prompts found for user, creating default');
        await _createDefaultSystemPrompt(user.id);
        return;
      }
      
      // Since we only allow one system prompt per user, take the first one
      final promptData = promptsData.first;
      print('[SystemPromptSync] Processing system prompt: ${promptData['id']}');
      final prompt = SystemPromptModel(
        id: promptData['id'],
        userId: promptData['user_id'],
        systemChatPrompt: promptData['system_chat_prompt'],
        systemTimerPrompt: promptData['system_timer_prompt'],
        createdAt: promptData['created_at'] != null ? DateTime.parse(promptData['created_at']) : DateTime.now(),
        updatedAt: promptData['updated_at'] != null ? DateTime.parse(promptData['updated_at']) : DateTime.now(),
      );

      final box = await Hive.openBox<SystemPromptModel>('system_prompts');
      print('[SystemPromptSync] Opened system_prompts box, current length: ${box.length}');
      
      // Clear existing cache and put the single prompt
      await box.clear();
      await box.put(prompt.id, prompt);
      print('[SystemPromptSync] Cache updated with single system prompt: ${prompt.id}');
      print('[SystemPromptSync] Sync completed successfully');
    } catch (e, stack) {
      print('[SystemPromptSync] Error syncing system prompts: $e');
      print('[SystemPromptSync] Stack trace: $stack');
      throw Exception('Failed to sync system prompts: $e');
    }
  }

  /// Create default system prompt for user
  Future<void> _createDefaultSystemPrompt(String userId) async {
    try {
      final defaultPrompt = {
        'user_id': userId,
        'system_chat_prompt': 'You are a professional Personal manager. Help the user manage their tasks, goals, and reminders effectively.',
        'system_timer_prompt': 'You are a timer prompt assistant. Help the user with scheduled AI prompts and task management.',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      final result = await _supabase.from('system_prompts').insert(defaultPrompt);
      print('[SystemPromptSync] Created default system prompt for user: $userId');
      
      // Also update cache with the default prompt
      final box = await Hive.openBox<SystemPromptModel>('system_prompts');
      final prompt = SystemPromptModel(
        id: (result as Map)['id'] as String,
        userId: userId,
        systemChatPrompt: defaultPrompt['system_chat_prompt'] as String,
        systemTimerPrompt: defaultPrompt['system_timer_prompt'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await box.put(prompt.id, prompt);
    } catch (e) {
      print('[SystemPromptSync] Error creating default system prompt: $e');
      throw Exception('Failed to create default system prompt: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final promptsChannel = _supabase.channel('system_prompts_realtime');
    _activeChannels.add(promptsChannel);
    print('[SystemPromptSync] Setting up real-time subscription for user: ${user.id}');
    promptsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'system_prompts',
      callback: (payload) {
        print('[SystemPromptSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete' && record != null && record['user_id'] != user.id) return;
        print('[SystemPromptSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<SystemPromptModel>('system_prompts');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[SystemPromptSync] Processing ${payload.eventType} for system prompt id: ${record['id']}');
            print('[SystemPromptSync] Record fields: id=${record['id']}, user_id=${record['user_id']}, system_chat_prompt=${record['system_chat_prompt']}, system_timer_prompt=${record['system_timer_prompt']}, created_at=${record['created_at']}, updated_at=${record['updated_at']}');
            final prompt = SystemPromptModel(
              id: record['id'],
              userId: record['user_id'],
              systemChatPrompt: record['system_chat_prompt'],
              systemTimerPrompt: record['system_timer_prompt'],
              createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : DateTime.now(),
              updatedAt: record['updated_at'] != null ? DateTime.parse(record['updated_at']) : DateTime.now(),
            );
            print('[SystemPromptSync] Created system prompt object: $prompt');
            box.put(prompt.id, prompt);
            print('[SystemPromptSync] Updated cache for system prompt: ${prompt.id}');
            print('[SystemPromptSync] Cache now has ${box.length} items');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[SystemPromptSync] Processing DELETE for system prompt id: ${record['id']}');
            box.delete(record['id']);
            print('[SystemPromptSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[SystemPromptSync] Error processing realtime: $e');
          print('[SystemPromptSync] Stack trace: $stack');
        }
      },
    );
    promptsChannel.subscribe();
    print('[SystemPromptSync] Real-time subscription subscribed');
  }

  /// Create system prompt
  Future<void> createSystemPrompt(SystemPromptModel prompt) async {
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
      'system_chat_prompt': prompt.systemChatPrompt,
      'system_timer_prompt': prompt.systemTimerPrompt,
      'created_at': prompt.createdAt.toUtc().toIso8601String(),
      'updated_at': prompt.updatedAt.toUtc().toIso8601String(),
    };

    await _supabase.from('system_prompts').insert(supabaseData);
  }

  /// Update system prompt
  Future<void> updateSystemPrompt(String id, SystemPromptModel prompt) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'system_chat_prompt': prompt.systemChatPrompt,
      'system_timer_prompt': prompt.systemTimerPrompt,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _supabase.from('system_prompts').update(supabaseData).eq('id', id);
  }

  /// Delete system prompt
  Future<void> deleteSystemPrompt(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    // Delete from Supabase
    await _supabase.from('system_prompts').delete().eq('id', id);

    // Immediately update local cache
    final box = await Hive.openBox<SystemPromptModel>('system_prompts');
    await box.delete(id);
    print('[SystemPromptSync] Deleted system prompt $id from local cache');
  }
}