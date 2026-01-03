// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledNotificationAdapter extends TypeAdapter<ScheduledNotification> {
  @override
  final int typeId = 4;

  @override
  ScheduledNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledNotification(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String?,
      scheduledDate: fields[3] as DateTime,
      payload: fields[4] as String,
      reminderType: fields[5] as ReminderType,
      options: (fields[6] as List?)?.cast<String>(),
      expectedAnswer: fields[7] as String?,
      aiPrompt: fields[8] as String?,
      userId: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledNotification obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.scheduledDate)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.reminderType)
      ..writeByte(6)
      ..write(obj.options)
      ..writeByte(7)
      ..write(obj.expectedAnswer)
      ..writeByte(8)
      ..write(obj.aiPrompt)
      ..writeByte(9)
      ..write(obj.userId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderTypeAdapter extends TypeAdapter<ReminderType> {
  @override
  final int typeId = 5;

  @override
  ReminderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderType.basic;
      case 1:
        return ReminderType.option;
      case 2:
        return ReminderType.answerBack;
      case 3:
        return ReminderType.aiPrompt;
      default:
        return ReminderType.basic;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderType obj) {
    switch (obj) {
      case ReminderType.basic:
        writer.writeByte(0);
        break;
      case ReminderType.option:
        writer.writeByte(1);
        break;
      case ReminderType.answerBack:
        writer.writeByte(2);
        break;
      case ReminderType.aiPrompt:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
