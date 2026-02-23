import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/cache/timer_prompt_cache.dart';
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/services/timer_prompt_sync_service.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/providers.dart';

class TimerPromptState {
  final List<TimerPrompt> prompts;

  const TimerPromptState({this.prompts = const []});

  TimerPromptState copyWith({List<TimerPrompt>? prompts}) {
    return TimerPromptState(prompts: prompts ?? this.prompts);
  }
}

class TimerPromptViewModel extends Notifier<TimerPromptState> {
  final TimerPromptCache _cache = TimerPromptCache();
  late final TimerPromptSyncService _syncService;

  @override
  TimerPromptState build() {
    _syncService = ref.watch(timerPromptSyncServiceProvider);
    _cache.watchAll().listen((prompts) {
      state = TimerPromptState(prompts: prompts);
    });
    return const TimerPromptState();
  }

  Future<void> savePrompt(TimerPrompt prompt) async {
    await _syncService.createTimerPrompt(prompt);
  }

  Future<void> updatePrompt(String id, TimerPrompt prompt) async {
    await _syncService.updateTimerPrompt(id, prompt);
  }

  Future<void> deletePrompt(String id) async {
    await _syncService.deleteTimerPrompt(id);
  }

  Future<void> executePrompt(TimerPrompt prompt) async {
    try {
      // Get current user from Riverpod
      final container = ProviderContainer();
      final user = container.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseGeminiService.sendChatMessage(user.id, prompt.prompt);
      final timestamp = DateTime.now();
      final newEntry = "[${timestamp.toIso8601String()}] $response";
      final existing = await _cache.get(prompt.id);
      if (existing != null) {
        final updated = TimerPrompt(
          id: existing.id,
          prompt: existing.prompt,
          scheduledTime: existing.scheduledTime,
          isRecurring: existing.isRecurring,
          weekdays: existing.weekdays,
          response: existing.response != null && existing.response!.isNotEmpty
              ? "$newEntry\n\n"+existing.response!
              : newEntry,
          userId: existing.userId,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await _cache.put(updated.id, updated);
      }
    } catch (e) {
      print('Error executing timer prompt: $e');
    }
  }

/// Shows a dialog to create/edit a TimerPrompt. `onSave` should persist via ViewModel.
Future<void> showTimerPromptDialog({
  required BuildContext context,
  TimerPrompt? existingPrompt,
  required Future<void> Function(TimerPrompt prompt) onSave,
}) async {
  final TextEditingController promptController = TextEditingController(
    text: existingPrompt?.prompt ?? '',
  );

  DateTime? selectedDate = existingPrompt?.scheduledTime.toLocal();
  TimeOfDay? selectedTime = existingPrompt != null
      ? TimeOfDay.fromDateTime(existingPrompt.scheduledTime.toLocal())
      : TimeOfDay.now();
  List<DateTime> scheduledDateTimes = [];
  String repeatOption = 'Never';
  List<int> selectedWeekdays = [];

  if (existingPrompt != null && existingPrompt.isRecurring) {
    if (existingPrompt.weekdays != null && existingPrompt.weekdays!.isNotEmpty) {
      repeatOption = 'Weekly';
      selectedWeekdays = List.from(existingPrompt.weekdays!);
    } else {
      repeatOption = 'Daily';
    }
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            existingPrompt == null ? 'Add Timer Prompt' : 'Edit Timer Prompt',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: promptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter AI Prompt',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Repeat', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: repeatOption,
                      dropdownColor: Colors.grey[700],
                      style: const TextStyle(color: Colors.white),
                      items: ['Never', 'Daily', 'Weekly']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => repeatOption = val!);
                      },
                    ),
                  ],
                ),
                if (repeatOption == 'Weekly')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final dayIndex = index + 1;
                        final isSelected = selectedWeekdays.contains(dayIndex);
                        return FilterChip(
                          label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedWeekdays.add(dayIndex);
                              } else {
                                selectedWeekdays.remove(dayIndex);
                              }
                            });
                          },
                          selectedColor: Colors.blue,
                          checkmarkColor: Colors.white,
                        );
                      }),
                    ),
                  ),
                if (repeatOption == 'Never')
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : DateFormat('MMM dd, yyyy').format(selectedDate!),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => selectedDate = picked);
                        },
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedTime == null ? 'Select Time' : selectedTime!.format(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time, color: Colors.white),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => selectedTime = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (repeatOption == 'Never')
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDate != null && selectedTime != null) {
                        final dt = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                        if (!scheduledDateTimes.contains(dt)) {
                          setState(() => scheduledDateTimes.add(dt));
                        }
                      }
                    },
                    child: const Text('Add Date & Time'),
                  ),
                if (repeatOption == 'Never' && scheduledDateTimes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: scheduledDateTimes
                      .map((dt) => Chip(
                            label: Text('${DateFormat('MMM dd, HH:mm').format(dt)} (IST)'),
                            onDeleted: () => setState(() => scheduledDateTimes.remove(dt)),
                          ))
                      .toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final text = promptController.text.trim();
                if (text.isEmpty) return;

                if (repeatOption != 'Never') {
                  if (selectedTime == null) return;
                  final now = DateTime.now();
                  final dt = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  ).toUtc();

                  final userId = ProviderScope.containerOf(context).read(currentUserProvider)?.id;
                  final TimerPrompt prompt = TimerPrompt(
                    id: existingPrompt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    prompt: text,
                    scheduledTime: dt,
                    isRecurring: true,
                    weekdays: repeatOption == 'Weekly' ? selectedWeekdays : null,
                    userId: userId,
                    createdAt: existingPrompt?.createdAt ?? now,
                    updatedAt: now,
                  );

                  await onSave(prompt);
                } else {
                  final List<DateTime> finalTimes =
                      scheduledDateTimes.map((dt) => dt.toUtc()).toList();
                  if (finalTimes.isEmpty && selectedDate != null && selectedTime != null) {
                    finalTimes.add(DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    ).toUtc());
                  }

                  if (existingPrompt != null) {
                    // Editing existing prompt
                    final now = DateTime.now();
                    final userId = ProviderScope.containerOf(context).read(currentUserProvider)?.id;
                    final p = TimerPrompt(
                      id: existingPrompt.id,
                      prompt: text,
                      scheduledTime: finalTimes[0], // Use the first (and should be only) time
                      isRecurring: false,
                      userId: userId,
                      createdAt: existingPrompt.createdAt,
                      updatedAt: now,
                    );
                    await onSave(p);
                  } else {
                    // Creating new prompts
                    for (int i = 0; i < finalTimes.length; i++) {
                      final now = DateTime.now();
                      final userId = ProviderScope.containerOf(context).read(currentUserProvider)?.id;
                      final p = TimerPrompt(
                        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                        prompt: text,
                        scheduledTime: finalTimes[i],
                        isRecurring: false,
                        userId: userId,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await onSave(p);
                    }
                  }
                }

                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      });
    },
  );
}
}

final timerPromptViewModelProvider = NotifierProvider<TimerPromptViewModel, TimerPromptState>(() => TimerPromptViewModel());
