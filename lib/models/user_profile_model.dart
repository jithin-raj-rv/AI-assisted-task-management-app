import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 9)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  List<dynamic>? personality;

  @HiveField(3)
  List<dynamic>? additionalInfo;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  UserProfile({
    this.id,
    this.userId,
    this.personality,
    this.additionalInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromHiveList(List<dynamic> list) {
    return UserProfile(
      id: list.length > 0 ? list[0] as String? : null,
      userId: list.length > 1 ? list[1] as String? : null,
      personality: list.length > 2 ? list[2] as List<dynamic>? : null,
      additionalInfo: list.length > 3 ? list[3] as List<dynamic>? : null,
      createdAt: list.length > 4 ? list[4] as DateTime? : null,
      updatedAt: list.length > 5 ? list[5] as DateTime? : null,
    );
  }

  List<dynamic> toHiveList() {
    return [
      id,
      userId,
      personality,
      additionalInfo,
      createdAt,
      updatedAt,
    ];
  }
}
