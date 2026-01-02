
import 'package:hive/hive.dart';

part 'todo_category_model.g.dart';

@HiveType(typeId: 1)
class TodoCategory {
  @HiveField(0)
  String importance;
  @HiveField(1)
  String urgency;

  TodoCategory({
    required this.importance,
    required this.urgency,
  });

  // Constructor to create a TodoCategory from the existing List<dynamic> format
  factory TodoCategory.fromHiveList(List<dynamic> data) {
    return TodoCategory(
      importance: data[0] as String,
      urgency: data[1] as String,
    );
  }

  // Method to convert a TodoCategory object back to the List<dynamic> format for Hive storage
  List<dynamic> toHiveList() {
    return [importance, urgency];
  }

  @override
  String toString() {
    return 'TodoCategory(importance: $importance, urgency: $urgency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TodoCategory &&
        other.importance == importance &&
        other.urgency == urgency;
  }

  @override
  int get hashCode => importance.hashCode ^ urgency.hashCode;
}
