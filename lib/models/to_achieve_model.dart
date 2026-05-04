import 'package:hive/hive.dart';

part 'to_achieve_model.g.dart';

@HiveType(typeId: 14)
class ToAchieve extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  String title;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  int priorityOrder;

  @HiveField(5)
  DateTime? targetDate;

  ToAchieve({
    this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = false,
    this.priorityOrder = 0,
    this.targetDate,
  });

  ToAchieve clone() {
    return ToAchieve(
      id: id,
      goalId: goalId,
      title: title,
      isCompleted: isCompleted,
      priorityOrder: priorityOrder,
      targetDate: targetDate,
    );
  }
}
