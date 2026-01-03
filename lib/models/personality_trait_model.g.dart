// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personality_trait_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonalityTraitAdapter extends TypeAdapter<PersonalityTrait> {
  @override
  final int typeId = 11;

  @override
  PersonalityTrait read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalityTrait(
      id: fields[0] as String?,
      userId: fields[1] as String?,
      trait: fields[2] as String,
      sortOrder: fields[3] as int,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalityTrait obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.trait)
      ..writeByte(3)
      ..write(obj.sortOrder)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalityTraitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
