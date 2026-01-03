import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/additional_info_model.dart';

class AdditionalInfoCache {
  static const String boxName = 'additional_info_items';

  Future<Box<AdditionalInfo>> get _box async => Hive.openBox<AdditionalInfo>(boxName);

  Future<void> put(String id, AdditionalInfo info) async {
    final box = await _box;
    await box.put(id, info);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<List<AdditionalInfo>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Stream<List<AdditionalInfo>> watchAll() async* {
    final box = await _box;
    print('[AdditionalInfoCache] watchAll: yielding initial ${box.values.length} info items');
    yield box.values.toList();
    await for (final event in box.watch()) {
      final infoItems = box.values.toList();
      print('[AdditionalInfoCache] watchAll: box changed (key: ${event.key}, deleted: ${event.deleted}), yielding ${infoItems.length} info items');
      yield infoItems;
    }
  }
}
