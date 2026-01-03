import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/todo_model.dart';

class TodoCache {
  static const String boxName = 'todos';

  Future<Box<Todo>> get _box async => Hive.openBox<Todo>(boxName);

  Future<void> put(String id, Todo todo) async {
    final box = await _box;
    await box.put(id, todo);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  Future<List<Todo>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Stream<List<Todo>> watchAll() async* {
    final box = await _box;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }
}
