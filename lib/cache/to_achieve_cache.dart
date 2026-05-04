import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/to_achieve_model.dart';

class ToAchieveCache {
  static const String boxName = 'to_achieves';
  
  Future<Box<ToAchieve>> get _box async => await Hive.openBox<ToAchieve>(boxName);

  Future<void> put(String id, ToAchieve toAchieve) async {
    final box = await _box;
    await box.put(id, toAchieve);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<ToAchieve?> get(String id) async {
    final box = await _box;
    return box.get(id);
  }

  Future<List<ToAchieve>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Stream<List<ToAchieve>> watchAll() async* {
    final box = await _box;
    yield box.values.toList();
    yield* box.watch().map((_) => box.values.toList());
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }
}
