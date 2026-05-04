import 'package:hive/hive.dart';

part 'system_model.g.dart';

@HiveType(typeId: 9)
class System extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  String systemName;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  int priorityOrder;

  @HiveField(5)
  String? userId;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  System({
    this.id,
    required this.goalId,
    required this.systemName,
    this.isCompleted = false,
    this.priorityOrder = 0,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  System clone() {
    return System(
      id: id,
      goalId: goalId,
      systemName: systemName,
      isCompleted: isCompleted,
      priorityOrder: priorityOrder,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'System(id: $id, goalId: $goalId, systemName: $systemName, isCompleted: $isCompleted, priorityOrder: $priorityOrder)';
  }
}
