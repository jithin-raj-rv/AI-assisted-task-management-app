import 'package:hive/hive.dart';

part 'user_settings_model.g.dart';

@HiveType(typeId: 10)
class UserSettings extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String? settingKey;

  @HiveField(3)
  Map<String, dynamic>? settingValue;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  UserSettings({
    this.id,
    this.userId,
    this.settingKey,
    this.settingValue,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromHiveList(List<dynamic> list) {
    return UserSettings(
      id: list.length > 0 ? list[0] as String? : null,
      userId: list.length > 1 ? list[1] as String? : null,
      settingKey: list.length > 2 ? list[2] as String? : null,
      settingValue: list.length > 3 ? list[3] as Map<String, dynamic>? : null,
      createdAt: list.length > 4 ? list[4] as DateTime? : null,
      updatedAt: list.length > 5 ? list[5] as DateTime? : null,
    );
  }

  List<dynamic> toHiveList() {
    return [
      id,
      userId,
      settingKey,
      settingValue,
      createdAt,
      updatedAt,
    ];
  }
}
