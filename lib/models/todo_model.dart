
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

  // Constructor to create a Todo from the existing List<dynamic> format
  factory Todo.fromHiveList(List<dynamic> data) {
    return Todo(
      taskName: data[0] as String? ?? '',
      isCompleted: data[1] as bool? ?? false,
      importance: data[2] as String? ?? 'NOT IMPORTANT',
      urgency: data[3] as String? ?? 'NOT URGENT',
      description: data[4] as String? ?? '',
      dueDate: data[5] as DateTime? ?? DateTime.now(),
      userId: data.length > 6 ? data[6] as String? : null,
      createdAt: data.length > 7 ? data[7] as DateTime? : null,
      updatedAt: data.length > 8 ? data[8] as DateTime? : null,
      isSynced: data.length > 9 ? data[9] as bool? ?? false : false,
      lastSyncAttempt: data.length > 10 ? data[10] as DateTime? : null,
    );
  }

  // Method to convert a Todo object back to the List<dynamic> format for Hive storage
  List<dynamic> toHiveList() {
    return [taskName, isCompleted, importance, urgency, description, dueDate, userId, createdAt, updatedAt, isSynced, lastSyncAttempt];
  }

  @override
  String toString() {
    return 'Todo(taskName: $taskName, isCompleted: $isCompleted, importance: $importance, urgency: $urgency)';
  }
}
