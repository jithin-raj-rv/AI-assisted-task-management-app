import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/personality_trait_model.dart';

class PersonalityCache {
  static const String boxName = 'personality_traits';

  Future<Box<PersonalityTrait>> get _box async => Hive.openBox<PersonalityTrait>(boxName);

  Future<void> put(String id, PersonalityTrait trait) async {
    final box = await _box;
    await box.put(id, trait);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<List<PersonalityTrait>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  Stream<List<PersonalityTrait>> watchAll() async* {
    final box = await _box;
    print('[PersonalityCache] watchAll: yielding initial ${box.values.length} traits');
    yield box.values.toList();
    await for (final event in box.watch()) {
      final traits = box.values.toList();
      print('[PersonalityCache] watchAll: box changed (key: ${event.key}, deleted: ${event.deleted}), yielding ${traits.length} traits');
      yield traits;
    }
  }
}
