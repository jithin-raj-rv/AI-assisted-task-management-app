import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/cache/timer_prompt_cache.dart';
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/services/timer_prompt_sync_service.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/providers.dart';

class TimerPromptState {
  final List<TimerPrompt> prompts;

  const TimerPromptState({this.prompts = const []});

  TimerPromptState copyWith({List<TimerPrompt>? prompts}) {
    return TimerPromptState(prompts: prompts ?? this.prompts);
  }
}

class TimerPromptViewModel extends Notifier<TimerPromptState> {
  final TimerPromptCache _cache = TimerPromptCache();
  late final TimerPromptSyncService _syncService;

  @override
  TimerPromptState build() {
    _syncService = ref.watch(timerPromptSyncServiceProvider);
    _cache.watchAll().listen((prompts) {
      state = TimerPromptState(prompts: prompts);
    });
    return const TimerPromptState();
  }

  Future<void> savePrompt(TimerPrompt prompt) async {
    await _syncService.createTimerPrompt(prompt);
  }

  Future<void> updatePrompt(String id, TimerPrompt prompt) async {
    await _syncService.updateTimerPrompt(id, prompt);
  }

  Future<void> deletePrompt(String id) async {
    await _syncService.deleteTimerPrompt(id);
  }

  Future<void> executePrompt(TimerPrompt prompt) async {
    try {
      final container = ProviderContainer();
      final user = container.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseGeminiService.sendChatMessage(user.id, prompt.prompt ?? '');
      final timestamp = DateTime.now();
      final newEntry = "[${timestamp.toIso8601String()}] $response";
      final existing = await _cache.get(prompt.id);
      if (existing != null) {
        final updated = TimerPrompt(
          id: existing.id,
          prompt: existing.prompt,
          scheduledTime: existing.scheduledTime,
          weekdays: existing.weekdays,
          recurringType: existing.recurringType,
          response: existing.response != null && existing.response!.isNotEmpty
              ? "$newEntry\n\n" + existing.response!
              : newEntry,
          userId: existing.userId,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await _cache.put(updated.id, updated);
      }
    } catch (e) {
      print('Error executing timer prompt: $e');
    }
  }
}

final timerPromptViewModelProvider = NotifierProvider<TimerPromptViewModel, TimerPromptState>(() => TimerPromptViewModel());
