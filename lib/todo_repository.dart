import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/main.dart'; // For global localNotificationService
import 'package:rxdart/rxdart.dart';

class TodoRepository {
  final Box<Todo> box;

  TodoRepository(this.box);

  Future<void> addTodo(Todo todo) async {
    await box.put(todo.id!, todo);
  }

  Future<void> deleteTodo(String id) async {
    await box.delete(id);
  }

  Future<void> updateTodo(String id, Todo updated) async {
    await box.put(id, updated);
  }

  Todo? getTodo(String id) {
    return box.get(id);
  }

  List<Todo> getAllTodos() {
    return box.values.toList();
  }

  Stream<List<Todo>> watchTodos() {
    return Rx.concat([
      Stream.value(box.values.toList()),
      box.watch().map((_) => box.values.toList())
    ]);
  }
}

// Goals Repository
class GoalsRepository {
  final Box<Goal> box;

  GoalsRepository(this.box);

  Future<void> addGoal(Goal goal) async {
    await box.put(goal.title, goal); // Using title as key for consistency
  }

  Future<void> deleteGoal(String title) async {
    await box.delete(title);
  }

  Future<void> updateGoal(String title, Goal updated) async {
    await box.put(title, updated);
  }

  Goal? getGoal(String title) {
    return box.get(title);
  }

  List<Goal> getAllGoals() {
    return box.values.toList();
  }

  Stream<List<Goal>> watchGoals() {
    return Rx.concat([
      Stream.value(box.values.toList()),
      box.watch().map((_) => box.values.toList())
    ]);
  }
}

// Timer Prompts Repository
class TimerPromptsRepository {
  final Box<TimerPrompt> box;

  TimerPromptsRepository(this.box);

  Future<void> addTimerPrompt(TimerPrompt prompt) async {
    await box.put(prompt.id, prompt);
  }

  Future<void> deleteTimerPrompt(String id) async {
    await box.delete(id);
  }

  Future<void> updateTimerPrompt(String id, TimerPrompt updated) async {
    await box.put(id, updated);
  }

  TimerPrompt? getTimerPrompt(String id) {
    return box.get(id);
  }

  List<TimerPrompt> getAllTimerPrompts() {
    return box.values.toList();
  }

  Stream<List<TimerPrompt>> watchTimerPrompts() {
    return Rx.concat([
      Stream.value(box.values.toList()),
      box.watch().map((_) => box.values.toList())
    ]);
  }
}

// Scheduled Notifications Repository
class ScheduledNotificationsRepository {
  final Box<ScheduledNotification> box;

  ScheduledNotificationsRepository(this.box);

  Future<void> addScheduledNotification(ScheduledNotification notification) async {
    await box.put(notification.id, notification);
    await localNotificationService.showScheduledNotification(notification: notification);
  }

  Future<void> deleteScheduledNotification(int id) async {
    await localNotificationService.cancelNotification(id);
    await box.delete(id);
  }

  Future<void> updateScheduledNotification(int id, ScheduledNotification updated) async {
    await localNotificationService.cancelNotification(id);
    await box.put(id, updated);
    await localNotificationService.showScheduledNotification(notification: updated);
  }

  ScheduledNotification? getScheduledNotification(int id) {
    return box.get(id);
  }

  List<ScheduledNotification> getAllScheduledNotifications() {
    return box.values.toList();
  }

  Stream<List<ScheduledNotification>> watchScheduledNotifications() {
    return Rx.concat([
      Stream.value(box.values.toList()),
      box.watch().map((_) => box.values.toList())
    ]);
  }
}

// User Feedback Repository
class UserFeedbackRepository {
  final Box<UserFeedback> box;

  UserFeedbackRepository(this.box);

  Future<void> addUserFeedback(UserFeedback feedback) async {
    await box.put(feedback.timestamp.millisecondsSinceEpoch, feedback);
  }

  Future<void> deleteUserFeedback(int timestamp) async {
    await box.delete(timestamp);
  }

  Future<void> updateUserFeedback(int timestamp, UserFeedback updated) async {
    await box.put(timestamp, updated);
  }

  UserFeedback? getUserFeedback(int timestamp) {
    return box.get(timestamp);
  }

  List<UserFeedback> getAllUserFeedback() {
    return box.values.toList();
  }

  Stream<List<UserFeedback>> watchUserFeedback() {
    return Rx.concat([
      Stream.value(box.values.toList()),
      box.watch().map((_) => box.values.toList())
    ]);
  }
}
