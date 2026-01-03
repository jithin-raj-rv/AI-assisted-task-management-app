import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/cache/scheduled_notification_cache.dart';
import 'package:to_do_list/services/reminder_sync_service.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:uuid/uuid.dart';

class ScheduledNotificationsState {
  final List<ScheduledNotification> notifications;

  const ScheduledNotificationsState({this.notifications = const []});

  ScheduledNotificationsState copyWith({List<ScheduledNotification>? notifications}) {
    return ScheduledNotificationsState(notifications: notifications ?? this.notifications);
  }
}

class ScheduledNotificationsViewModel extends Notifier<ScheduledNotificationsState> {
  final ScheduledNotificationCache _cache = ScheduledNotificationCache();
  late final ReminderSyncService _syncService;

  @override
  ScheduledNotificationsState build() {
    _syncService = ref.watch(reminderSyncServiceProvider);
    _cache.watchAll().listen((notifications) {
      state = ScheduledNotificationsState(notifications: notifications);
    });
    return const ScheduledNotificationsState();
  }

  Future<void> addNotification(ScheduledNotification notification) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    final notificationWithId = ScheduledNotification(
      id: newId,
      title: notification.title,
      body: notification.body,
      scheduledDate: notification.scheduledDate,
      payload: notification.payload,
      reminderType: notification.reminderType,
      options: notification.options,
      expectedAnswer: notification.expectedAnswer,
      aiPrompt: notification.aiPrompt,
    );

    await _syncService.createReminder(notificationWithId);
  }

  Future<void> updateNotification(String id, ScheduledNotification updated) async {
    await _syncService.updateReminder(id, updated);
  }

  Future<void> deleteNotification(String id) async {
    await _syncService.deleteReminder(id);
  }
}

final scheduledNotificationsViewModelProvider =
    NotifierProvider<ScheduledNotificationsViewModel, ScheduledNotificationsState>(() => ScheduledNotificationsViewModel());
