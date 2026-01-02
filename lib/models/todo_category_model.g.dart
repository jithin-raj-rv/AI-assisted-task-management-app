// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoCategoryAdapter extends TypeAdapter<TodoCategory> {
  @override
  final int typeId = 1;

  @override
  TodoCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoCategory(
      importance: fields[0] as String,
      urgency: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TodoCategory obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.importance)
      ..writeByte(1)
      ..write(obj.urgency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
