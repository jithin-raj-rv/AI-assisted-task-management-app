import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/util/remainderdialogbox.dart';
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/viewmodels/user_feedback_viewmodel.dart';
import 'package:to_do_list/viewmodels/timer_prompt_viewmodel.dart';
import 'package:to_do_list/viewmodels/scheduled_notifications_viewmodel.dart';
import 'package:to_do_list/main.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ReminderPageViewModel {
  final Ref ref;

  ReminderPageViewModel(this.ref);

  Future<void> showAddReminderDialog(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return RemainderDialogBox(
          controller: titleController,
          onSave: (title, description, reminderDateTimes, reminderType, options, expectedAnswer, aiPrompt) async {
            await saveReminder(title, description, reminderDateTimes, reminderType, options, expectedAnswer, aiPrompt);
          },
          onCancel: () {
            titleController.clear();
            descriptionController.clear();
            Navigator.of(context).pop();
          },
          initialDescription: '',
          initialReminderDate: null,
          initialReminderType: ReminderType.basic,
          initialOptions: null,
          initialExpectedAnswer: null,
          initialAiPrompt: null,
        );
      },
    );
  }

  Future<void> saveReminder(
    String title,
    String description,
    List<DateTime> reminderDateTimes,
    ReminderType reminderType,
    List<String>? options,
    String? expectedAnswer,
    String? aiPrompt,
  ) async {
    if (title.isNotEmpty && reminderDateTimes.isNotEmpty) {
      const uuid = Uuid();
      for (var date in reminderDateTimes) {
        final now = DateTime.now();
        final userId = ref.read(currentUserProvider)?.id;
        final newReminder = ScheduledNotification(
          id: uuid.v4(),
          title: title,
          body: description,
          scheduledDate: date,
          payload: 'reminder_${DateTime.now().millisecondsSinceEpoch}_${date.millisecondsSinceEpoch}',
          reminderType: reminderType,
          options: options,
          expectedAnswer: expectedAnswer,
          aiPrompt: aiPrompt,
          userId: userId,
          createdAt: now,
          updatedAt: now,
        );

        await ref.read(scheduledNotificationsViewModelProvider.notifier).addNotification(newReminder);
        // Schedule the notification with the local notification plugin (main isolate)
        try {
          await localNotificationService.showScheduledNotification(notification: newReminder);
        } catch (e) {
          print('[ReminderVM] Failed to schedule local notification: $e');
        }
      }
    }
  }

  Future<void> showEditReminderDialog(BuildContext context, ScheduledNotification reminder) async {
    final TextEditingController titleController = TextEditingController(text: reminder.title);
    final TextEditingController descriptionController = TextEditingController(text: reminder.body ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return RemainderDialogBox(
          controller: titleController,
          onSave: (title, description, reminderDateTimes, reminderType, options, expectedAnswer, aiPrompt) async {
            await editReminder(reminder, title, description, reminderDateTimes, reminderType, options, expectedAnswer, aiPrompt);
          },
          onCancel: () {
            titleController.clear();
            descriptionController.clear();
            Navigator.of(context).pop();
          },
          initialDescription: reminder.body,
          initialReminderDate: reminder.scheduledDate,
          initialReminderType: reminder.reminderType,
          initialOptions: reminder.options,
          initialExpectedAnswer: reminder.expectedAnswer,
          initialAiPrompt: reminder.aiPrompt,
        );
      },
    );
  }

  Future<void> editReminder(
    ScheduledNotification reminder,
    String title,
    String description,
    List<DateTime> reminderDateTimes,
    ReminderType reminderType,
    List<String>? options,
    String? expectedAnswer,
    String? aiPrompt,
  ) async {
    if (title.isNotEmpty && reminderDateTimes.isNotEmpty) {
      // Update the main reminder
      final updated = ScheduledNotification(
        id: reminder.id,
        title: title,
        body: description,
        scheduledDate: reminderDateTimes[0],
        payload: reminder.payload,
        reminderType: reminderType,
        options: options,
        expectedAnswer: expectedAnswer,
        aiPrompt: aiPrompt,
        userId: ref.read(currentUserProvider)?.id,
        createdAt: reminder.createdAt,
        updatedAt: DateTime.now(),
      );
      await ref.read(scheduledNotificationsViewModelProvider.notifier).updateNotification(reminder.id, updated);

      // If there are more dates, create new reminders
      const uuid = Uuid();
        for (int i = 1; i < reminderDateTimes.length; i++) {
        final newReminder = ScheduledNotification(
          id: uuid.v4(),
          title: title,
          body: description,
          scheduledDate: reminderDateTimes[i],
          payload: 'reminder_${DateTime.now().millisecondsSinceEpoch}_${i}',
          reminderType: reminderType,
          options: options,
          expectedAnswer: expectedAnswer,
          aiPrompt: aiPrompt,
          userId: ref.read(currentUserProvider)?.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(scheduledNotificationsViewModelProvider.notifier).addNotification(newReminder);
        try {
          await localNotificationService.showScheduledNotification(notification: newReminder);
        } catch (e) {
          print('[ReminderVM] Failed to schedule local notification: $e');
        }
      }
    }
  }

  Future<void> deleteReminder(ScheduledNotification reminder) async {
    await ref.read(scheduledNotificationsViewModelProvider.notifier).deleteNotification(reminder.id);
    try {
      await localNotificationService.cancelNotification(reminder.id);
    } catch (e) {
      print('[ReminderVM] Failed to cancel local notification: $e');
    }
  }

  /// Core feedback processing logic.  Can be called from anywhere
  /// (including notification handlers) and optionally shows a SnackBar if
  /// a [BuildContext] is provided.
  Future<void> processFeedback(
    ScheduledNotification notification,
    String response, {
    BuildContext? context,
  }) async {
    final now = DateTime.now();
    final userId = ref.read(currentUserProvider)?.id;
    final feedback = UserFeedback(
      feedback: "Reminder '${notification.title}': $response",
      timestamp: now,
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
    );

    await ref.read(userFeedbackViewModelProvider.notifier).addFeedback(feedback);
    await ref.read(scheduledNotificationsViewModelProvider.notifier).deleteNotification(notification.id);

    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted: $response')),
      );
    }
  }

  Future<void> handleFeedback(BuildContext context, ScheduledNotification notification, String response) async {
    await processFeedback(notification, response, context: context);
  }

  Future<void> handleAIPrompt(BuildContext context, ScheduledNotification notification) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt = (notification.aiPrompt != null && notification.aiPrompt!.isNotEmpty) ? notification.aiPrompt! : notification.title;
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final response = await SupabaseGeminiService.sendChatMessage(user.id, prompt);
      Navigator.of(context).pop(); // Pop loading

      // If this reminder was tied to a TimerPrompt, persist the response there
      if (notification.payload.startsWith('timer_prompt_')) {
        final parts = notification.payload.split('_');
        if (parts.length >= 3) {
          final promptId = parts[2];
          try {
            final timerPromptState = ref.read(timerPromptViewModelProvider);
            final timerPrompt = timerPromptState.prompts.firstWhere((p) => p.id == promptId);
            final timestamp = DateFormat('MMM dd, HH:mm').format(DateTime.now());
            final newEntry = "[$timestamp] $response";
            final updated = TimerPrompt(
              id: timerPrompt.id,
              prompt: timerPrompt.prompt,
              scheduledTime: timerPrompt.scheduledTime,
              isRecurring: timerPrompt.isRecurring,
              weekdays: timerPrompt.weekdays,
              response: timerPrompt.response != null && timerPrompt.response!.isNotEmpty ? "$newEntry\n\n${timerPrompt.response}" : newEntry,
              userId: timerPrompt.userId,
              createdAt: timerPrompt.createdAt,
              updatedAt: DateTime.now(),
            );
            await ref.read(timerPromptViewModelProvider.notifier).savePrompt(updated);
          } catch (e) {
            // ignore if timer prompt not found
          }
        }
      }

      // Show the AI response and allow removing the reminder
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(child: Text(response)),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await deleteReminder(notification);
              },
              child: const Text('Delete Reminder'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
