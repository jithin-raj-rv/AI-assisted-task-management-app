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



  Goal({
    this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    this.isCompleted = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
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
    );
  }

  // Method to convert a Goal object back to the List<dynamic> format for Hive storage
  List<dynamic> toHiveList() {
    return [title, description, targetDate, isCompleted, id, userId, createdAt, updatedAt];
  }

  @override
  String toString() {
    return 'Goal(title: $title, description: $description, targetDate: $targetDate, isCompleted: $isCompleted)';
  }
}
