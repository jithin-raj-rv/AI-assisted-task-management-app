import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/viewmodels/timer_prompt_viewmodel.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/main.dart'; // To access db
import 'package:to_do_list/util/timer_prompt_tile.dart';
import 'package:to_do_list/providers.dart'; // For currentUserProvider

class TimerPromptPage extends ConsumerStatefulWidget {
  const TimerPromptPage({super.key});

  @override
  ConsumerState<TimerPromptPage> createState() => _TimerPromptPageState();
}

class _TimerPromptPageState extends ConsumerState<TimerPromptPage> {
  final TextEditingController _promptController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<DateTime> _scheduledDateTimes = [];

  // Helper to generate consistent IDs for notifications based on prompt ID and index
  int _getNotificationId(String promptId, int index) {
    return (promptId.hashCode + index) & 0x7FFFFFFF;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }


  // Function to schedule notifications based on TimerPrompt
  Future<void> _scheduleNotificationsForPrompt(TimerPrompt prompt) async {
    // 1. Cleanup existing notifications for this prompt ID
    // Since we don't store them in the shared list, we cancel a range of potential IDs
    for (int i = 0; i < 50; i++) {
      final id = _getNotificationId(prompt.id, i);
      await localNotificationService.cancelNotification(id);
    }

    // 2. Generate Dates to Schedule
    List<DateTime> datesToSchedule = [];
    DateTime now = DateTime.now();
    DateTime start = prompt.scheduledTime;

    if (!prompt.isRecurring) {
      // If it's in the past, we might skip it or let it fire immediately depending on requirement.
      // Here we schedule it as is.
      datesToSchedule.add(start);
    } else {
      // Recurring logic: Schedule next 30 occurrences to ensure it works for a while
      int limit = 30;
      
      if (prompt.weekdays != null && prompt.weekdays!.isNotEmpty) {
        // Weekly on specific days
        int currentCount = 0;
        // Start checking from today at the scheduled time
        DateTime cursor = DateTime(now.year, now.month, now.day, start.hour, start.minute);
        // If that time has passed today, start checking from tomorrow
        if (cursor.isBefore(now)) cursor = cursor.add(const Duration(days: 1));

        // Look ahead day by day
        while (currentCount < limit) {
          if (prompt.weekdays!.contains(cursor.weekday)) {
            datesToSchedule.add(cursor);
            currentCount++;
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      } else {
        // Daily
        DateTime cursor = DateTime(now.year, now.month, now.day, start.hour, start.minute);
        if (cursor.isBefore(now)) cursor = cursor.add(const Duration(days: 1));
        
        for (int i = 0; i < limit; i++) {
          datesToSchedule.add(cursor.add(Duration(days: i)));
        }
      }
    }
  }

  void _deletePrompt(TimerPrompt prompt) async {
    await ref.read(timerPromptViewModelProvider.notifier).deletePrompt(prompt.id);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final prompts = ref.watch(timerPromptViewModelProvider).prompts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: "Timer Prompts"),
      ),
      body: Container(
        color: appTheme.background,
        child: prompts.isEmpty
            ? Center(
                child: Text(
                  'No timer prompts scheduled.',
                  style: TextStyle(color: appTheme.primary),
                ),
              )
            : ListView.builder(
                itemCount: prompts.length,
                itemBuilder: (context, index) {
                  final prompt = prompts[index];
                  return TimerPromptTile(
                    timerPrompt: prompt,
                    onDelete: _deletePrompt,
                    onEdit: (p) => ref.read(timerPromptViewModelProvider.notifier).showTimerPromptDialog(
                      context: context,
                      existingPrompt: p,
                      onSave: (prompt) async {
                        try {
                          final vm = ref.read(timerPromptViewModelProvider.notifier);
                          await vm.updatePrompt(p.id, prompt);
                        } catch (e) {
                          print('Error updating timer prompt: $e');
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(timerPromptViewModelProvider.notifier).showTimerPromptDialog(
          context: context,
          onSave: (prompt) async {
            try {
              final vm = ref.read(timerPromptViewModelProvider.notifier);
              await vm.savePrompt(prompt);
            } catch (e) {
              print('Error saving timer prompt: $e');
            }
          },
        ),
        backgroundColor: appTheme.primaryGradient1,
        child: const Icon(Icons.add, color: Colors.white),
      ));
  }
}
