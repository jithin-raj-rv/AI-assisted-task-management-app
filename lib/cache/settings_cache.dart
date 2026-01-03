import 'package:hive_flutter/hive_flutter.dart';

class SettingsCache {
  static const String boxName = 'settings';

  Future<Box> get _box async => Hive.openBox(boxName);

  Future<dynamic> get(String key, {dynamic defaultValue}) async {
    final box = await _box;
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> put(String key, dynamic value) async {
    final box = await _box;
    await box.put(key, value);
  }
}
