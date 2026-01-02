import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/todo_repository.dart';

// Repository Providers
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(Hive.box<Todo>('todos'));
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(Hive.box<Goal>('goals'));
});

final timerPromptsRepositoryProvider = Provider<TimerPromptsRepository>((ref) {
  return TimerPromptsRepository(Hive.box<TimerPrompt>('timer_prompts'));
});

final scheduledNotificationsRepositoryProvider =
    Provider<ScheduledNotificationsRepository>((ref) {
  return ScheduledNotificationsRepository(
      Hive.box<ScheduledNotification>('scheduled_notifications'));
});

final userFeedbackRepositoryProvider = Provider<UserFeedbackRepository>((ref) {
  return UserFeedbackRepository(Hive.box<UserFeedback>('user_feedback'));
});

// Stream Providers for reactive data
final todosProvider = StreamProvider<List<Todo>>((ref) {
  return ref.watch(todoRepositoryProvider).watchTodos();
});

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchGoals();
});

final timerPromptsProvider = StreamProvider<List<TimerPrompt>>((ref) {
  return ref.watch(timerPromptsRepositoryProvider).watchTimerPrompts();
});

final scheduledNotificationsProvider =
    StreamProvider<List<ScheduledNotification>>((ref) {
  return ref.watch(scheduledNotificationsRepositoryProvider).watchScheduledNotifications();
});

final userFeedbackProvider = StreamProvider<List<UserFeedback>>((ref) {
  return ref.watch(userFeedbackRepositoryProvider).watchUserFeedback();
});

// Settings Provider (untyped box)
final settingsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final box = Hive.box('settings');

  // Ensure defaults are set
  if (box.get('personality') == null) {
    await box.put('personality', [
      "Introvert",
      "Logical thinker",
      "Independent",
      "Problem solver",
      "Curious learner",
      "Calm under pressure",
      "Observant",
      "Practical mindset"
    ]);
  }
  if (box.get('additional_info') == null) {
    await box.put('additional_info', [
      "Enjoys working alone or in small teams",
      "Learns best by doing projects",
      "Prefers clear goals over vague plans",
      "Interested in technology and startups",
      "Values freedom and flexibility",
      "Focuses on efficiency and results",
      "Takes time to open up socially",
      "Motivated by skill mastery"
    ]);
  }

  yield Map<String, dynamic>.from(box.toMap());

  await for (final _ in box.watch()) {
    yield Map<String, dynamic>.from(box.toMap());
  }
});

// Auth Providers
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user;
});
