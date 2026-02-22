import 'package:hive/hive.dart';

part 'goal_step_model.g.dart';

@HiveType(typeId: 9)
class GoalStep extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  String stepText;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  int sortOrder;

  @HiveField(5)
  String? userId;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  GoalStep({
    this.id,
    required this.goalId,
    required this.stepText,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  GoalStep clone() {
    return GoalStep(
      id: id,
      goalId: goalId,
      stepText: stepText,
      isCompleted: isCompleted,
      sortOrder: sortOrder,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'GoalStep(id: $id, goalId: $goalId, stepText: $stepText, isCompleted: $isCompleted, sortOrder: $sortOrder)';
  }
}