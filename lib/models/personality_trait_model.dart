import 'package:hive/hive.dart';

part 'personality_trait_model.g.dart';

@HiveType(typeId: 11)
class PersonalityTrait extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String trait;

  @HiveField(3)
  int sortOrder;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  PersonalityTrait({
    this.id,
    this.userId,
    required this.trait,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory PersonalityTrait.fromJson(Map<String, dynamic> json) {
    return PersonalityTrait(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      trait: json['trait'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trait': trait,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PersonalityTrait copyWith({
    String? id,
    String? userId,
    String? trait,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalityTrait(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trait: trait ?? this.trait,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
