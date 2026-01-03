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
  bool isRecurring;

  @HiveField(4)
  List<int>? weekdays;

  @HiveField(5)
  String id;

  @HiveField(6)
  bool sent;

  @HiveField(7)
  String? userId;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? updatedAt;

  TimerPrompt({
    required this.prompt,
    required this.scheduledTime,
    this.response,
    this.isRecurring = false,
    this.weekdays,
    required this.id,
    this.sent = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory TimerPrompt.fromHiveList(List<dynamic> list) {
    return TimerPrompt(
      prompt: list[0] as String,
      scheduledTime: list[1] as DateTime,
      response: list.length > 2 ? list[2] as String? : null,
      isRecurring: list.length > 3 ? list[3] as bool : false,
      weekdays: list.length > 4 ? (list[4] as List<dynamic>?)?.cast<int>() : null,
      id: list.length > 5 ? list[5] as String : DateTime.now().millisecondsSinceEpoch.toString(),
      sent: list.length > 6 ? list[6] as bool : false,
      userId: list.length > 7 ? list[7] as String? : null,
      createdAt: list.length > 8 ? list[8] as DateTime? : null,
      updatedAt: list.length > 9 ? list[9] as DateTime? : null,
    );
  }

  List<dynamic> toHiveList() {
    return [prompt, scheduledTime, response, isRecurring, weekdays, id, sent, userId, createdAt, updatedAt];
  }
}
