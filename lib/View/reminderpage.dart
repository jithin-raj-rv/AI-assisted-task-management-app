import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/main.dart'; // To access localNotificationService
import 'package:to_do_list/util/remainderdialogbox.dart'; // Import RemainderDialogBox
import 'package:to_do_list/util/notificationtile.dart'; // Import NotificationTile
import 'package:to_do_list/AI/gemini.dart';
import 'package:intl/intl.dart';

class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {

  @override
  void initState() {
    super.initState();
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Function to save a new scheduled notification
  void _saveReminder(
    String title,
    String description,
    List<DateTime> reminderDateTimes, // Changed to List
    ReminderType reminderType, // New parameter
    List<String>? options, // New parameter
    String? expectedAnswer, // New parameter
    String? aiPrompt, // New parameter
  ) async {
    Navigator.of(context).pop(); // Close the dialog

    if (title.isNotEmpty && reminderDateTimes.isNotEmpty) {
      for (var date in reminderDateTimes) {
        final newReminder = ScheduledNotification(
          id: (db.scheduledNotifications.isEmpty ? 0 : db.scheduledNotifications.map((e) => e.id).reduce((a, b) => a > b ? a : b)) + 1 + db.scheduledNotifications.length, // Ensure unique ID even in loop
          title: title,
          body: description,
          scheduledDate: date,
          payload: 'reminder_${DateTime.now().millisecondsSinceEpoch}_${date.millisecondsSinceEpoch}',
          reminderType: reminderType,
          options: options,
          expectedAnswer: expectedAnswer,
          aiPrompt: aiPrompt,
        );

        db.scheduledNotifications.add(newReminder);
        
        // We need to update data here or after loop. 
        // But to get unique IDs correctly if relying on list length, we add immediately.
        
        await localNotificationService.showScheduledNotification(
          notification: newReminder,
        );
      }
      db.updatedata(); // Save once after loop

      setState(() {}); // Rebuild the UI to show the new reminder
    }

    _titleController.clear();
    _descriptionController.clear();
  }

  // Function to add a new scheduled notification
  void _addReminder() {
    showDialog(
      context: context,
      builder: (context) {
        return RemainderDialogBox(
          controller: _titleController,
          onSave: _saveReminder,
          onCancel: () {
            _titleController.clear();
            _descriptionController.clear();
            Navigator.of(context).pop();
          },
          initialDescription: '',
          initialReminderDate: null,
          initialReminderType: ReminderType.basic, // Default for new reminder
          initialOptions: null,
          initialExpectedAnswer: null,
          initialAiPrompt: null,
        );
      },
    );
  }

  // Function to edit an existing scheduled notification
  void _editReminder(ScheduledNotification reminder) {
    _titleController.text = reminder.title;
    _descriptionController.text = reminder.body!;

    showDialog(
      context: context,
      builder: (context) {
        return RemainderDialogBox(
          controller: _titleController,
          onSave: (title, description, reminderDateTimes, reminderType, options, expectedAnswer, aiPrompt) async {
            Navigator.of(context).pop(); // Close the dialog

            if (title.isNotEmpty && reminderDateTimes.isNotEmpty) {
              // Find and update the existing reminder
              final index = db.scheduledNotifications.indexWhere((element) => element.id == reminder.id);
              if (index != -1) {
                // Update the existing one with the first date
                db.scheduledNotifications[index] = ScheduledNotification(
                  id: reminder.id,
                  title: title,
                  body: description,
                  scheduledDate: reminderDateTimes[0],
                  payload: reminder.payload,
                  reminderType: reminderType, // New
                  options: options, // New
                  expectedAnswer: expectedAnswer, // New
                  aiPrompt: aiPrompt, // New
                );
                db.updatedata(); // Save the updated list to Hive

                // Reschedule the notification
                await localNotificationService.cancelNotification(reminder.id);
                await localNotificationService.showScheduledNotification(
                  notification: db.scheduledNotifications[index],
                );

                // If there are more dates, create new reminders for them
                for (int i = 1; i < reminderDateTimes.length; i++) {
                   final newReminder = ScheduledNotification(
                    id: (db.scheduledNotifications.map((e) => e.id).reduce((a, b) => a > b ? a : b)) + 1,
                    title: title,
                    body: description,
                    scheduledDate: reminderDateTimes[i],
                    payload: 'reminder_${DateTime.now().millisecondsSinceEpoch}_${i}',
                    reminderType: reminderType,
                    options: options,
                    expectedAnswer: expectedAnswer,
                    aiPrompt: aiPrompt,
                  );
                  db.scheduledNotifications.add(newReminder);
                  await localNotificationService.showScheduledNotification(
                    notification: newReminder,
                  );
                }
                db.updatedata();

                setState(() {}); // Rebuild the UI
              }
            }
            _titleController.clear();
            _descriptionController.clear();
          },
          onCancel: () {
            _titleController.clear();
            _descriptionController.clear();
            Navigator.of(context).pop();
          },
          initialDescription: reminder.body,
          initialReminderDate: reminder.scheduledDate,
          initialReminderType: reminder.reminderType, // New
          initialOptions: reminder.options, // New
          initialExpectedAnswer: reminder.expectedAnswer, // New
          initialAiPrompt: reminder.aiPrompt, // New
        );
      },
    );
  }

  // Function to delete a scheduled notification
  void _deleteReminder(ScheduledNotification reminder) async {
    // Cancel the scheduled notification
    await localNotificationService.cancelNotification(reminder.id);

    // Remove from the list and update Hive
    db.scheduledNotifications.removeWhere((element) => element.id == reminder.id);
    db.updatedata();
    setState(() {}); // Rebuild the UI
  }

  // Function to handle feedback submission
  void _handleFeedback(ScheduledNotification notification, String response) {
    final feedback = UserFeedback(
      feedback: "Reminder '${notification.title}': $response",
      timestamp: DateTime.now(),
    );
    db.userFeedback.add(feedback);
    _deleteReminder(notification);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted: $response')),
    );
  }

  // Function to handle AI Prompt
  void _handleAIPrompt(ScheduledNotification notification) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt = notification.aiPrompt != null && notification.aiPrompt!.isNotEmpty ? notification.aiPrompt! : notification.title;
      final response = await sendChatMessage(ref, prompt);
      Navigator.of(context).pop(); // Pop loading

      // Save response to TimerPrompt if applicable
      if (notification.payload.startsWith('timer_prompt_')) {
        final parts = notification.payload.split('_');
        if (parts.length >= 3) {
          final promptId = parts[2];
          try {
            final timerPrompt = db.timerPrompts.firstWhere((p) => p.id == promptId);
            final timestamp = DateFormat('MMM dd, HH:mm').format(DateTime.now());
            final newEntry = "[$timestamp] $response";
            
            if (timerPrompt.response != null && timerPrompt.response!.isNotEmpty) {
               timerPrompt.response = "$newEntry\n\n${timerPrompt.response}";
            } else {
               timerPrompt.response = newEntry;
            }
            db.updatedata(); 
          } catch (e) {
            print("TimerPrompt not found: $e");
          }
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(child: Text(response)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReminder(notification);
              },
              child: const Text('Close & Delete'),
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

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: "My Reminders"),
      ),
      body: Container(
        color: appTheme.background,
        child: db.scheduledNotifications.isEmpty
            ? Center(
                child: Text(
                  'No reminders scheduled yet!',
                  style: TextStyle(color: appTheme.primary),
                ),
              )
            : ListView.builder(
                itemCount: db.scheduledNotifications.length,
                itemBuilder: (context, index) {
                  final reminder = db.scheduledNotifications[index];
                  return NotificationTile(
                    notification: reminder,
                    onDelete: _deleteReminder,
                    onEdit: _editReminder, // Pass the edit function here
                    onFeedback: _handleFeedback, // Pass the feedback function here
                    onAiPrompt: _handleAIPrompt,
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: appTheme.primaryGradient1,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
