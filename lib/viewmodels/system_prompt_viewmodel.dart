import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/system_prompt_model.dart';
import 'package:to_do_list/cache/system_prompt_cache.dart';
import 'package:to_do_list/services/system_prompt_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_list/sync_providers.dart';

class SystemPromptState {
  final List<SystemPromptModel> systemPrompts;
  final bool isLoading;

  const SystemPromptState({this.systemPrompts = const [], this.isLoading = false});

  SystemPromptState copyWith({List<SystemPromptModel>? systemPrompts, bool? isLoading}) {
    return SystemPromptState(
      systemPrompts: systemPrompts ?? this.systemPrompts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SystemPromptViewModel extends Notifier<SystemPromptState> {
  final SystemPromptCache _cache = SystemPromptCache();
  late final SystemPromptSyncService _syncService;

  @override
  SystemPromptState build() {
    _syncService = ref.watch(systemPromptSyncServiceProvider);
    
    // Load initial data from cache immediately
    _loadInitialData();
    
    // Then watch for changes
    _cache.watchAll().listen((prompts) {
      print('[SystemPromptViewModel] Cache updated with ${prompts.length} system prompts: ${prompts.map((p) => p.id).toList()}');
      state = SystemPromptState(systemPrompts: prompts, isLoading: false);
    });
    print('[SystemPromptViewModel] Built SystemPromptViewModel');
    return const SystemPromptState(isLoading: true);
  }

  Future<void> _loadInitialData() async {
    try {
      final prompts = await _cache.getAll();
      if (prompts.isNotEmpty) {
        state = SystemPromptState(systemPrompts: prompts, isLoading: false);
        print('[SystemPromptViewModel] Loaded ${prompts.length} initial system prompts from cache');
      }
    } catch (e) {
      print('[SystemPromptViewModel] Error loading initial data: $e');
    }
  }

  Future<void> createSystemPrompt({
    required String systemChatPrompt,
    required String systemTimerPrompt,
  }) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    final prompt = SystemPromptModel(
      id: newId,
      userId: '', // Will be set by sync service
      systemChatPrompt: systemChatPrompt,
      systemTimerPrompt: systemTimerPrompt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _syncService.createSystemPrompt(prompt);
  }

  Future<void> updateSystemPrompt(SystemPromptModel prompt) async {
    await _syncService.updateSystemPrompt(prompt.id, prompt);
  }

  Future<void> deleteSystemPrompt(String id) async {
    await _syncService.deleteSystemPrompt(id);
  }
}

final systemPromptViewModelProvider =
    NotifierProvider<SystemPromptViewModel, SystemPromptState>(() => SystemPromptViewModel());