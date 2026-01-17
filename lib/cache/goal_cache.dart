import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/goal_model.dart';

class GoalCache {
  static const String boxName = 'goals';

  Future<Box<Goal>> get _box async => Hive.openBox<Goal>(boxName);

  Future<void> put(String id, Goal goal) async {
    final box = await _box;
    await box.put(id, goal);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<List<Goal>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  Stream<List<Goal>> watchAll() async* {
    final box = await _box;
    print('[GoalCache] watchAll: yielding initial ${box.values.length} goals');
    yield box.values.toList();
    await for (final event in box.watch()) {
      final goals = box.values.toList();
      print('[GoalCache] watchAll: box changed (key: ${event.key}, deleted: ${event.deleted}), yielding ${goals.length} goals');
      yield goals;
    }
  }
}
