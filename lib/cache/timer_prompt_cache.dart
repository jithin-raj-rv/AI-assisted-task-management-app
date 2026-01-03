import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';

class TimerPromptCache {
  static const String boxName = 'timer_prompts';

  Future<Box<TimerPrompt>> get _box async => Hive.openBox<TimerPrompt>(boxName);

  Future<void> put(String id, TimerPrompt prompt) async {
    final box = await _box;
    await box.put(id, prompt);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<TimerPrompt?> get(String id) async {
    final box = await _box;
    return box.get(id);
  }

  Future<List<TimerPrompt>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Stream<List<TimerPrompt>> watchAll() async* {
    final box = await _box;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }
}
