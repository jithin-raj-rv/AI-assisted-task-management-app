// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'to_achieve_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ToAchieveAdapter extends TypeAdapter<ToAchieve> {
  @override
  final int typeId = 14;

  @override
  ToAchieve read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToAchieve(
      id: fields[0] as String?,
      goalId: fields[1] as String,
      title: fields[2] as String,
      isCompleted: fields[3] as bool,
      priorityOrder: fields[4] as int,
      targetDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ToAchieve obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.priorityOrder)
      ..writeByte(5)
      ..write(obj.targetDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToAchieveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
