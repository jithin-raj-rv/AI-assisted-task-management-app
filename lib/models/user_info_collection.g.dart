// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_collection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 2;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      text: fields[1] as String,
      type: fields[2] as QuestionType,
      options: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.options);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionTypeAdapter extends TypeAdapter<QuestionType> {
  @override
  final int typeId = 3;

  @override
  QuestionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestionType.text;
      case 1:
        return QuestionType.number;
      case 2:
        return QuestionType.singleChoice;
      case 3:
        return QuestionType.multiChoice;
      case 4:
        return QuestionType.paragraph;
      default:
        return QuestionType.text;
    }
  }

  @override
  void write(BinaryWriter writer, QuestionType obj) {
    switch (obj) {
      case QuestionType.text:
        writer.writeByte(0);
        break;
      case QuestionType.number:
        writer.writeByte(1);
        break;
      case QuestionType.singleChoice:
        writer.writeByte(2);
        break;
      case QuestionType.multiChoice:
        writer.writeByte(3);
        break;
      case QuestionType.paragraph:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
