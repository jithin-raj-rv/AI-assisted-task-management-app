import 'package:hive/hive.dart';

part 'additional_info_model.g.dart';

@HiveType(typeId: 12)
class AdditionalInfo extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String info;

  @HiveField(3)
  int sortOrder;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  AdditionalInfo({
    this.id,
    this.userId,
    required this.info,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    return AdditionalInfo(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      info: json['info'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'info': info,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AdditionalInfo copyWith({
    String? id,
    String? userId,
    String? info,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdditionalInfo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      info: info ?? this.info,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
