import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/user_feedback_model.dart';

class UserFeedbackCache {
  static const String boxName = 'user_feedback';

  Future<Box<UserFeedback>> get _box async => Hive.openBox<UserFeedback>(boxName);

  Future<void> put(String id, UserFeedback feedback) async {
    final box = await _box;
    await box.put(id, feedback);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<List<UserFeedback>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Stream<List<UserFeedback>> watchAll() async* {
    final box = await _box;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }
}
