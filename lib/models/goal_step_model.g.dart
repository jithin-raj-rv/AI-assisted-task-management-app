// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_step_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalStepAdapter extends TypeAdapter<GoalStep> {
  @override
  final int typeId = 9;

  @override
  GoalStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalStep(
      id: fields[0] as String?,
      goalId: fields[1] as String,
      stepText: fields[2] as String,
      isCompleted: fields[3] as bool,
      sortOrder: fields[4] as int,
      userId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GoalStep obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.stepText)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.sortOrder)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
