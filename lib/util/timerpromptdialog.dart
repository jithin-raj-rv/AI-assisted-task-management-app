import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/gradienttextfield.dart';
import 'package:to_do_list/util/smalltextgradient.dart';
import 'package:to_do_list/providers.dart';

class Timerpromptdialog extends ConsumerStatefulWidget {
  final TimerPrompt? existingPrompt;
  final Future<void> Function(TimerPrompt prompt) onSave;

  const Timerpromptdialog({
    super.key,
    this.existingPrompt,
    required this.onSave,
  });

  @override
  ConsumerState<Timerpromptdialog> createState() => _TimerpromptdialogState();
}

class _TimerpromptdialogState extends ConsumerState<Timerpromptdialog> {
  late TextEditingController _promptController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final List<int> _selectedWeekdays = [];
  String _repeatOption = 'never';

  final List<String> _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.existingPrompt?.prompt ?? '');
    
    if (widget.existingPrompt != null) {
      _selectedDate = widget.existingPrompt!.scheduledTime.toLocal();
      _selectedTime = TimeOfDay.fromDateTime(widget.existingPrompt!.scheduledTime.toLocal());
      
      if (widget.existingPrompt!.recurringType != null && widget.existingPrompt!.recurringType != 'never') {
        _repeatOption = widget.existingPrompt!.recurringType!;
        if (_repeatOption == 'weekly' && widget.existingPrompt!.weekdays != null) {
          _selectedWeekdays.addAll(widget.existingPrompt!.weekdays!);
        }
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        _selectedWeekdays.remove(day);
      } else {
        _selectedWeekdays.add(day);
      }
    });
  }

  Future<void> _save() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final userId = ref.read(currentUserProvider)?.id;

    if (_repeatOption != 'never') {
      // Recurring
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toUtc();

      final prompt = TimerPrompt(
        id: widget.existingPrompt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: text,
        scheduledTime: dt,
        weekdays: _repeatOption == 'weekly' ? _selectedWeekdays : null,
        recurringType: _repeatOption.toLowerCase(),
        userId: userId,
        createdAt: widget.existingPrompt?.createdAt ?? now,
        updatedAt: now,
      );

      await widget.onSave(prompt);
    } else {
      // Not recurring
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toUtc();

      final prompt = TimerPrompt(
        id: widget.existingPrompt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: text,
        scheduledTime: scheduledDateTime,
        recurringType: _repeatOption.toLowerCase(),
        userId: userId,
        createdAt: widget.existingPrompt?.createdAt ?? now,
        updatedAt: now,
      );

      await widget.onSave(prompt);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return AlertDialog(
      scrollable: true,
      backgroundColor: appTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Smalltextgradient(
        text: widget.existingPrompt == null ? 'Add Timer Prompt' : 'Edit Timer Prompt',
        fontsize: 22,
      ),
      content: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gradienttextfield(controller: _promptController, text: 'Prompt'),
              const SizedBox(height: 16),
    
              // Repeat Option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Smalltextgradient(
                    text: 'Repeat:',
                    fontsize: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [appTheme.primary, appTheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _repeatOption,
                      dropdownColor: appTheme.primary,
                      style: TextStyle(color: appTheme.background),
                      underline: const SizedBox(),
                      items: ['Never', 'Daily', 'Weekly']
                          .map((e) => DropdownMenuItem(value: e.toLowerCase(), child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _repeatOption = val!;
                          if (_repeatOption == 'never') {
                            _selectedWeekdays.clear();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekday Selection (only if weekly)
              if (_repeatOption == 'weekly') ...[
                const SizedBox(height: 8),
                const Smalltextgradient(
                  text: 'Select Days:',
                  fontsize: 15,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = _selectedWeekdays.contains(day);
                    return ChoiceChip(
                      label: Text(
                        _weekdayNames[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : appTheme.background,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: appTheme.primary,
                      backgroundColor: appTheme.primary.withOpacity(0.3),
                      onSelected: (_) => _toggleWeekday(day),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Date Selection (only if not recurring)
              if (_repeatOption == 'never') ...[
                Row(
                  children: [
                    Expanded(
                      child: Smalltextgradient(
                        fontsize: 15,
                        text: 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Smalltextgradient(
                        text: 'Select',
                        fontsize: 15,
                      ),
                    ),
                  ],
                ),
              ],

              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: Smalltextgradient(
                      fontsize: 15,
                      text: 'Time: ${_selectedTime.format(context)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context),
                    child: Smalltextgradient(
                      text: 'Select',
                      fontsize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Buttonstyl(
                      savetext: 'Save',
                      onPressed: _save,
                    ),
                    const SizedBox(width: 8),
                    Buttonstyl(
                      savetext: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the styled timer prompt dialog
Future<void> showTimerPromptDialog({
  required BuildContext context,
  TimerPrompt? existingPrompt,
  required Future<void> Function(TimerPrompt prompt) onSave,
}) async {
  await showDialog(
    context: context,
    builder: (context) => Timerpromptdialog(
      existingPrompt: existingPrompt,
      onSave: onSave,
    ),
  );
}
