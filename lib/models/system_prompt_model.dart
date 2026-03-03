import 'package:hive/hive.dart';
import 'package:supabase/supabase.dart';

part 'system_prompt_model.g.dart';

@HiveType(typeId: 13)
class SystemPromptModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String systemChatPrompt;
  @HiveField(3)
  final String systemTimerPrompt;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime updatedAt;

  SystemPromptModel({
    required this.id,
    required this.userId,
    required this.systemChatPrompt,
    required this.systemTimerPrompt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SystemPromptModel.fromMap(Map<String, dynamic> map) {
    return SystemPromptModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      systemChatPrompt: map['system_chat_prompt'] as String,
      systemTimerPrompt: map['system_timer_prompt'] as String,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'system_chat_prompt': systemChatPrompt,
      'system_timer_prompt': systemTimerPrompt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  SystemPromptModel copyWith({
    String? id,
    String? userId,
    String? systemChatPrompt,
    String? systemTimerPrompt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SystemPromptModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      systemChatPrompt: systemChatPrompt ?? this.systemChatPrompt,
      systemTimerPrompt: systemTimerPrompt ?? this.systemTimerPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
