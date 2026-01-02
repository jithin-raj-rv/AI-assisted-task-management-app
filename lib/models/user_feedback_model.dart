import 'package:hive/hive.dart';

part 'user_feedback_model.g.dart';

@HiveType(typeId: 6)
class UserFeedback extends HiveObject {
  @HiveField(0)
  String feedback;

  @HiveField(1)
  DateTime timestamp;

  UserFeedback({
    required this.feedback,
    required this.timestamp,
  });

  // Factory constructor for creating a UserFeedback from a Hive List
  factory UserFeedback.fromHiveList(List<dynamic> list) {
    return UserFeedback(
      feedback: list[0] as String,
      timestamp: list[1] as DateTime,
    );
  }

  // Method for converting a UserFeedback to a Hive List
  List<dynamic> toHiveList() {
    return [
      feedback,
      timestamp,
    ];
  }
}