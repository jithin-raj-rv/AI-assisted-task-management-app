import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';

class ScheduledNotificationCache {
  static const String boxName = 'scheduled_notifications';

  Future<Box<ScheduledNotification>> get _box async => Hive.openBox<ScheduledNotification>(boxName);

  Future<void> put(String id, ScheduledNotification notification) async {
    final box = await _box;
    await box.put(id, notification);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<List<ScheduledNotification>> getAll() async {
    final box = await _box;
    final list = box.values.toList();
    print('[Cache] getAll() returning ${list.length} notifications');
    for (var i = 0; i < list.length; i++) {
      print('[Cache] Notification $i: id=${list[i].id} (${list[i].id.runtimeType}), title=${list[i].title}');
    }
    return list;
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  Stream<List<ScheduledNotification>> watchAll() async* {
    final box = await _box;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }
}
