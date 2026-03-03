import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/system_prompt_model.dart';

class SystemPromptCache {
  static const String boxName = 'system_prompts';

  Future<Box<SystemPromptModel>> get _box async => Hive.openBox<SystemPromptModel>(boxName);

  Future<void> put(String id, SystemPromptModel systemPrompt) async {
    final box = await _box;
    await box.put(id, systemPrompt);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  Future<List<SystemPromptModel>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Stream<List<SystemPromptModel>> watchAll() async* {
    final box = await _box;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }
}