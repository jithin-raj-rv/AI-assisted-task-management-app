import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/services/todo_sync_service.dart';
import 'package:to_do_list/services/goal_sync_service.dart';
import 'package:to_do_list/services/goal_step_sync_service.dart';
import 'package:to_do_list/services/reminder_sync_service.dart';
import 'package:to_do_list/services/settings_sync_service.dart';
import 'package:to_do_list/services/timer_prompt_sync_service.dart';
import 'package:to_do_list/services/personality_sync_service.dart';
import 'package:to_do_list/services/additional_info_sync_service.dart';
import 'package:to_do_list/services/user_feedback_sync_service.dart';

// Sync Service Providers
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final userFeedbackSyncServiceProvider = Provider<UserFeedbackSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return UserFeedbackSyncService(connectivity);
});

final todoSyncServiceProvider = Provider<TodoSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return TodoSyncService(connectivity);
});

final goalSyncServiceProvider = Provider<GoalSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return GoalSyncService(connectivity);
});

final goalStepSyncServiceProvider = Provider<GoalStepSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return GoalStepSyncService(connectivity);
});

final reminderSyncServiceProvider = Provider<ReminderSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return ReminderSyncService(connectivity);
});

final settingsSyncServiceProvider = Provider<SettingsSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return SettingsSyncService(connectivity);
});

final timerPromptSyncServiceProvider = Provider<TimerPromptSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return TimerPromptSyncService(connectivity);
});

final personalitySyncServiceProvider = Provider<PersonalitySyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return PersonalitySyncService(connectivity);
});

final additionalInfoSyncServiceProvider = Provider<AdditionalInfoSyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return AdditionalInfoSyncService(connectivity);
});
