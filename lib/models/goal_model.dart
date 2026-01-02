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



  Goal({
    this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    this.isCompleted = false,
  });

  Goal clone() {
    return Goal(
      id: id,
      title: title,
      description: description,
      targetDate: targetDate,
      isCompleted: isCompleted,
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
    );
  }

  // Method to convert a Goal object back to the List<dynamic> format for Hive storage
  List<dynamic> toHiveList() {
    return [title, description, targetDate, isCompleted, id];
  }

  @override
  String toString() {
    return 'Goal(title: $title, description: $description, targetDate: $targetDate, isCompleted: $isCompleted)';
  }
}
