// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_prompt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerPromptAdapter extends TypeAdapter<TimerPrompt> {
  @override
  final int typeId = 7;

  @override
  TimerPrompt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerPrompt(
      prompt: fields[0] as String,
      scheduledTime: fields[1] as DateTime,
      response: fields[2] as String?,
      isRecurring: fields[3] as bool,
      weekdays: (fields[4] as List?)?.cast<int>(),
      id: fields[5] as String,
      sent: fields[6] as bool,
      userId: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimerPrompt obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.prompt)
      ..writeByte(1)
      ..write(obj.scheduledTime)
      ..writeByte(2)
      ..write(obj.response)
      ..writeByte(3)
      ..write(obj.isRecurring)
      ..writeByte(4)
      ..write(obj.weekdays)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.sent)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerPromptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
