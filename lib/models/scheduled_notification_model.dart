import 'package:hive/hive.dart';

part 'scheduled_notification_model.g.dart';

@HiveType(typeId: 5)
enum ReminderType {
  @HiveField(0)
  basic,
  @HiveField(1)
  option,
  @HiveField(2)
  answerBack,
  @HiveField(3)
  aiPrompt,
}

@HiveType(typeId: 4)
class ScheduledNotification extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? body;

  @HiveField(3)
  DateTime scheduledDate;

  @HiveField(4)
  String payload;

  @HiveField(5)
  ReminderType reminderType;

  @HiveField(6)
  List<String>? options;

  @HiveField(7)
  String? expectedAnswer;

  @HiveField(8)
  String? aiPrompt;

  ScheduledNotification({
    required this.id,
    required this.title,
    this.body,
    required this.scheduledDate,
    required this.payload,
    this.reminderType = ReminderType.basic,
    this.options,
    this.expectedAnswer,
    this.aiPrompt,
  });

  factory ScheduledNotification.fromHiveList(List<dynamic> list) {
    return ScheduledNotification(
      id: list[0] as int,
      title: list[1] as String,
      body: list[2] as String?,
      scheduledDate: list[3] as DateTime,
      payload: list[4] as String,
      reminderType: list.length > 5 ? (list[5] as ReminderType) : ReminderType.basic,
      options: list.length > 6 ? (list[6] as List<dynamic>?)?.cast<String>() : null,
      expectedAnswer: list.length > 7 ? list[7] as String? : null,
      aiPrompt: list.length > 8 ? list[8] as String? : null,
    );
  }

  List<dynamic> toHiveList() {
    return [
      id,
      title,
      body,
      scheduledDate,
      payload,
      reminderType,
      options,
      expectedAnswer,
      aiPrompt,
    ];
  }

  ScheduledNotification clone() {
    return ScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      reminderType: reminderType,
      options: options != null ? List.from(options!) : null,
      expectedAnswer: expectedAnswer,
      aiPrompt: aiPrompt,
    );
  }
}