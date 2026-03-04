import 'package:hive/hive.dart';

part 'timer_prompt_model.g.dart';

@HiveType(typeId: 7)
class TimerPrompt extends HiveObject {
  @HiveField(0)
  String prompt;

  @HiveField(1)
  DateTime scheduledTime;

  @HiveField(2)
  String? response;

  @HiveField(3)
  List<int>? weekdays;

  @HiveField(5)
  String? recurringType;

  @HiveField(6)
  String id;

  @HiveField(7)
  bool sent;

  @HiveField(8)
  String? userId;

  @HiveField(9)
  DateTime? createdAt;

  @HiveField(10)
  DateTime? updatedAt;

  TimerPrompt({
    required this.prompt,
    required this.scheduledTime,
    this.response,
    this.weekdays,
    this.recurringType,
    required this.id,
    this.sent = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

}
