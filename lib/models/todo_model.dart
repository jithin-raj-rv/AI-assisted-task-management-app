
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
  DateTime? dueDate;
  @HiveField(7)
  String? userId;
  @HiveField(8)
  DateTime? createdAt;
  @HiveField(9)
  DateTime? updatedAt;
  @HiveField(10)
  bool isSynced;
  @HiveField(11)
  DateTime? lastSyncAttempt;
  

  Todo({
    this.id,
    required this.taskName,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.importance,
    required this.urgency,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.lastSyncAttempt,
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
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
      lastSyncAttempt: lastSyncAttempt,
    );
  }

  Todo copyWith({
    String? id,
    String? taskName,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? importance,
    String? urgency,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAttempt,
  }) {
    return Todo(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      importance: importance ?? this.importance,
      urgency: urgency ?? this.urgency,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }


  @override
  String toString() {
    return 'Todo(taskName: $taskName, isCompleted: $isCompleted, importance: $importance, urgency: $urgency)';
  }
}
