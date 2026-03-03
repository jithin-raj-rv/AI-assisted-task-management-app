import 'package:hive/hive.dart';

part 'user_feedback_model.g.dart';

@HiveType(typeId: 6)
class UserFeedback extends HiveObject {
  @HiveField(0)
  String feedback;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  String? id;

  @HiveField(3)
  String? userId;

  UserFeedback({
    required this.feedback,
    required this.timestamp,
    this.id,
    this.userId,
  });

  // Factory constructor for creating a UserFeedback from a Hive List
  factory UserFeedback.fromHiveList(List<dynamic> list) {
    return UserFeedback(
      feedback: list[0] as String,
      timestamp: list[1] as DateTime,
      id: list.length > 2 ? list[2] as String? : null,
      userId: list.length > 3 ? list[3] as String? : null,
    );
  }

  // Method for converting a UserFeedback to a Hive List
  List<dynamic> toHiveList() {
    return [
      feedback,
      timestamp,
      id,
      userId,
    ];
  }

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'],
      userId: json['user_id'],
      feedback: json['feedback'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}