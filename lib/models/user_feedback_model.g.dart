// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_feedback_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserFeedbackAdapter extends TypeAdapter<UserFeedback> {
  @override
  final int typeId = 6;

  @override
  UserFeedback read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserFeedback(
      feedback: fields[0] as String,
      timestamp: fields[1] as DateTime,
      id: fields[2] as String?,
      userId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserFeedback obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.feedback)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserFeedbackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
