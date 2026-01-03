import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Supabase access removed from UI; use providers for auth where needed
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/main.dart'; // To access localNotificationService
import 'package:to_do_list/util/remainderdialogbox.dart'; // Import RemainderDialogBox
import 'package:to_do_list/util/notificationtile.dart'; // Import NotificationTile
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/providers.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/viewmodels/reminder_page_viewmodel.dart';
import 'package:to_do_list/viewmodels/user_feedback_viewmodel.dart';
import 'package:to_do_list/viewmodels/timer_prompt_viewmodel.dart';
import 'package:to_do_list/viewmodels/scheduled_notifications_viewmodel.dart';

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

  // Function to add a new scheduled notification
  void _addReminder() {
    final viewModel = ref.read(reminderPageViewModelProvider);
    viewModel.showAddReminderDialog(context);
  }

  // Function to edit an existing scheduled notification
  void _editReminder(ScheduledNotification reminder) {
    final viewModel = ref.read(reminderPageViewModelProvider);
    viewModel.showEditReminderDialog(context, reminder);
  }

  // Function to delete a scheduled notification
  void _deleteReminder(ScheduledNotification reminder) async {
    final viewModel = ref.read(reminderPageViewModelProvider);
    await viewModel.deleteReminder(reminder);
  }

  // Function to handle feedback submission
  Future<void> _handleFeedback(ScheduledNotification notification, String response) async {
    final viewModel = ref.read(reminderPageViewModelProvider);
    await viewModel.handleFeedback(context, notification, response);
  }

  // Function to handle AI Prompt
  Future<void> _handleAIPrompt(ScheduledNotification notification) async {
    final viewModel = ref.read(reminderPageViewModelProvider);
    await viewModel.handleAIPrompt(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final reminders = ref.watch(scheduledNotificationsViewModelProvider).notifications;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: "My Reminders"),
      ),
      body: Container(
        color: appTheme.background,
        child: reminders.isEmpty
            ? Center(
                child: Text(
                  'No reminders scheduled yet!',
                  style: TextStyle(color: appTheme.primary),
                ),
              )
            : ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
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
