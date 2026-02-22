import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/goal_step_model.dart';

class GoalStepCache {
  static const String _boxName = 'goal_steps';

  Future<Box<GoalStep>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<GoalStep>(_boxName);
    }
    return Hive.box<GoalStep>(_boxName);
  }

  Future<void> put(String id, GoalStep goalStep) async {
    final box = await _openBox();
    await box.put(id, goalStep);
  }

  Future<GoalStep?> get(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  Future<List<GoalStep>> getAll() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<void> putAll(Map<String, GoalStep> goalSteps) async {
    final box = await _openBox();
    await box.putAll(goalSteps);
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    final box = await _openBox();
    await box.deleteAll(ids);
  }

  Stream<List<GoalStep>> watchAll() async* {
    final box = await _openBox();
    print('[GoalStepCache] watchAll: yielding initial ${box.values.length} goal steps');
    yield box.values.toList();
    await for (final event in box.watch()) {
      final steps = box.values.toList();
      print('[GoalStepCache] watchAll: box changed (key: ${event.key}, deleted: ${event.deleted}), yielding ${steps.length} goal steps');
      yield steps;
    }
  }
}
