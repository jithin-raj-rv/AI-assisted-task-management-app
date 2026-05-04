import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/system_model.dart';

class SystemCache {
  static const String _boxName = 'systems';

  Future<Box<System>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<System>(_boxName);
    }
    return Hive.box<System>(_boxName);
  }

  Future<void> put(String id, System system) async {
    final box = await _openBox();
    await box.put(id, system);
  }

  Future<System?> get(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  Future<List<System>> getAll() async {
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

  Future<void> putAll(Map<String, System> systems) async {
    final box = await _openBox();
    await box.putAll(systems);
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    final box = await _openBox();
    await box.deleteAll(ids);
  }

  Stream<List<System>> watchAll() async* {
    final box = await _openBox();
    print('[SystemCache] watchAll: yielding initial ${box.values.length} systems');
    yield box.values.toList();
    await for (final event in box.watch()) {
      final systems = box.values.toList();
      print('[SystemCache] watchAll: box changed (key: ${event.key}, deleted: ${event.deleted}), yielding ${systems.length} systems');
      yield systems;
    }
  }
}