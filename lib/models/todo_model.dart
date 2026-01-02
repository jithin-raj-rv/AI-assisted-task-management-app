
import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String taskName;
  @HiveField(2)
  bool isCompleted;
  @HiveField(3)
  String importance;
  @HiveField(4)
  String urgency;
  @HiveField(5)
  String description;
  @HiveField(6)
  DateTime dueDate;
  

  Todo({
    this.id,
    required this.taskName,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.importance,
    required this.urgency,
  });

  Todo clone() {
    return Todo(
      id: id,
      taskName: taskName,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted,
      importance: importance,
      urgency: urgency,
    );
  }

  // Constructor to create a Todo from the existing List<dynamic> format
  factory Todo.fromHiveList(List<dynamic> data) {
    return Todo(
      taskName: data[0] as String,
      isCompleted: data[1] as bool,
      importance: data[2] as String,
      urgency: data[3] as String,
      description: data[4] as String,
      dueDate: data [5] as DateTime
    );
  }

  // Method to convert a Todo object back to the List<dynamic> format for Hive storage
  List<dynamic> toHiveList() {
    return [taskName, isCompleted, importance, urgency, description, dueDate];
  }

  @override
  String toString() {
    return 'Todo(taskName: $taskName, isCompleted: $isCompleted, importance: $importance, urgency: $urgency)';
  }
}
