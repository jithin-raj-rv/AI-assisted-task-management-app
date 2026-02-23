import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 8)
class Goal extends HiveObject {


  @HiveField(0)
  String? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime targetDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  String? userId;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  @HiveField(8)
  String importance;

  @HiveField(9)
  String urgency;



  Goal({
    this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    this.isCompleted = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.importance = 'NOT IMPORTANT',
    this.urgency = 'NOT URGENT',
  });

  Goal clone() {
    return Goal(
      id: id,
      title: title,
      description: description,
      targetDate: targetDate,
      isCompleted: isCompleted,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      importance: importance,
      urgency: urgency,
    );
  }
    // Constructor to create a Goal from the existing List<dynamic> format
  factory Goal.fromHiveList(List<dynamic> data) {
    return Goal(
      id: data.length > 4 ? data[4] as String? : null,
      title: data[0] as String,
      description: data[1] as String,
      targetDate: data[2] as DateTime,
      isCompleted: data[3] as bool,
      userId: data.length > 5 ? data[5] as String? : null,
      createdAt: data.length > 6 ? data[6] as DateTime? : null,
      updatedAt: data.length > 7 ? data[7] as DateTime? : null,
      importance: data.length > 8 ? data[8] as String? ?? 'NOT IMPORTANT' : 'NOT IMPORTANT',
      urgency: data.length > 9 ? data[9] as String? ?? 'NOT URGENT' : 'NOT URGENT',
    );
  }

  // Method to convert a Goal object back to the List<dynamic> format for Hive storage
  List<dynamic> toHiveList() {
    return [title, description, targetDate, isCompleted, id, userId, createdAt, updatedAt, importance, urgency];
  }

  @override
  String toString() {
    return 'Goal(title: $title, description: $description, targetDate: $targetDate, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Goal &&
        other.importance == importance &&
        other.urgency == urgency;
  }

  @override
  int get hashCode => importance.hashCode ^ urgency.hashCode;
}
