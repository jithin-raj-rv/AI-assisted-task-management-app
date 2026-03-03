import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/gradienttextfield.dart';
import 'package:to_do_list/util/smalltextgradient.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';

class RemainderDialogBox extends ConsumerStatefulWidget {
  const RemainderDialogBox({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.initialDescription,
    this.initialReminderDate,
    this.initialReminderType = ReminderType.basic,
    this.initialOptions,
    this.initialExpectedAnswer,
    this.initialAiPrompt,
  });

  final TextEditingController controller;
  final String? initialDescription;
  final DateTime? initialReminderDate;
  final VoidCallback onCancel;
  final Function(
    String name,
    String description,
    List<DateTime> reminderDateTimes,
    ReminderType reminderType,
    List<String>? options,
    String? expectedAnswer,
    String? aiPrompt,
  ) onSave;

  final ReminderType initialReminderType;
  final List<String>? initialOptions;
  final String? initialExpectedAnswer;
  final String? initialAiPrompt;

  @override
  ConsumerState<RemainderDialogBox> createState() => _RemainderDialogBoxState();
}

class _RemainderDialogBoxState extends ConsumerState<RemainderDialogBox> {
  late TextEditingController _descriptionController;
  DateTime? _selectedReminderDate;
  TimeOfDay? _selectedTime;
  final List<DateTime> _scheduledDateTimes = [];

  late ReminderType _selectedReminderType;
  late TextEditingController _newOptionController;
  late List<String> _options;
  late TextEditingController _expectedAnswerController;
  late TextEditingController _aiPromptController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _selectedReminderDate = widget.initialReminderDate?.toLocal();
    if (_selectedReminderDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(_selectedReminderDate!);
    }

    _selectedReminderType = widget.initialReminderType;
    _newOptionController = TextEditingController();
    _options = List<String>.from(widget.initialOptions ?? []);
    _expectedAnswerController = TextEditingController(text: widget.initialExpectedAnswer);
    _aiPromptController = TextEditingController(text: widget.initialAiPrompt);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _newOptionController.dispose();
    _expectedAnswerController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedReminderDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addOption() {
    if (_newOptionController.text.isNotEmpty) {
      setState(() {
        _options.add(_newOptionController.text);
        _newOptionController.clear();
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _addDateTime() {
    if (_selectedReminderDate != null && _selectedTime != null) {
      final dateTime = DateTime(
        _selectedReminderDate!.year,
        _selectedReminderDate!.month,
        _selectedReminderDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      if (!_scheduledDateTimes.contains(dateTime)) {
        setState(() {
          _scheduledDateTimes.add(dateTime);
        });
      }
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
      content: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gradienttextfield(controller: widget.controller, text: 'Reminder Title'),
              const SizedBox(height: 16),
              Gradienttextfield(controller: _descriptionController, text: 'Description (optional)'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Smalltextgradient(
                      fontsize: 15,
                      text: _selectedReminderDate == null
                          ? 'No reminder date selected'
                          : 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedReminderDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Smalltextgradient(
                      text: 'Select Date',
                      fontsize: 15,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: Smalltextgradient(
                      fontsize: 15,
                      text: _selectedTime == null
                          ? 'No time selected'
                          : 'Time: ${_selectedTime!.format(context)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context),
                    child: const Smalltextgradient(
                      text: 'Select Time',
                      fontsize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // Add Time Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [appTheme.primary, appTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  onPressed: _addDateTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add Date & Time"),
                ),
              ),

              // Display selected times
              if (_scheduledDateTimes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: _scheduledDateTimes.map((dateTime) {
                      final formattedTime = DateFormat('MMM dd, HH:mm').format(dateTime);
                      return Chip(
                        label: Text(
                          '$formattedTime (IST)',
                          style: TextStyle(fontSize: 12, color: appTheme.background),
                        ),
                        backgroundColor: appTheme.primary,
                        onDeleted: () {
                          setState(() {
                            _scheduledDateTimes.remove(dateTime);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 10),
              // Reminder Type Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Smalltextgradient(
                    text: 'Reminder Type:',
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
                    child: DropdownButton<ReminderType>(
                      value: _selectedReminderType,
                      dropdownColor: appTheme.primary,
                      style: TextStyle(color: appTheme.background),
                      underline: const SizedBox(),
                      onChanged: (ReminderType? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedReminderType = newValue;
                          });
                        }
                      },
                      items: ReminderType.values.map<DropdownMenuItem<ReminderType>>(
                        (ReminderType type) {
                          String typeName = type.toString().split('.').last;
                          typeName = typeName[0].toUpperCase() + typeName.substring(1);
                          return DropdownMenuItem<ReminderType>(
                            value: type,
                            child: Text(typeName),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Conditional UI for Option Reminders
              if (_selectedReminderType == ReminderType.option) ...[
                Row(
                  children: [
                    Expanded(
                      child: Gradienttextfield(controller: _newOptionController, text: 'Add an option'),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: appTheme.primary),
                      onPressed: _addOption,
                    ),
                  ],
                ),
                if (_options.isNotEmpty)
                  Column(
                    children: _options.asMap().entries.map((entry) {
                      int index = entry.key;
                      String option = entry.value;
                      return ListTile(
                        title: Smalltextgradient(text: option, fontsize: 14),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: appTheme.tertiary),
                          onPressed: () => _removeOption(index),
                        ),
                      );
                    }).toList(),
                  ),
              ],

              // Conditional UI for Answer Back Reminders
              if (_selectedReminderType == ReminderType.answerBack)
                Gradienttextfield(controller: _expectedAnswerController, text: 'Expected Answer (optional)'),

              // Conditional UI for AI Prompt Reminders
              if (_selectedReminderType == ReminderType.aiPrompt)
                Gradienttextfield(controller: _aiPromptController, text: 'AI Prompt (e.g., Give me a quote)'),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Buttonstyl(
                      savetext: 'Save',
                      onPressed: () {
                        if (_selectedReminderType == ReminderType.option &&
                            _newOptionController.text.trim().isNotEmpty) {
                          _options.add(_newOptionController.text.trim());
                        }

                        List<DateTime> finalDateTimes = List.from(_scheduledDateTimes);

                        if (finalDateTimes.isEmpty && _selectedReminderDate != null) {
                          DateTime dt;
                          if (_selectedTime != null) {
                            dt = DateTime(
                              _selectedReminderDate!.year,
                              _selectedReminderDate!.month,
                              _selectedReminderDate!.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );
                          } else {
                            dt = DateTime(
                              _selectedReminderDate!.year,
                              _selectedReminderDate!.month,
                              _selectedReminderDate!.day,
                            );
                          }
                          finalDateTimes.add(dt.toUtc());
                        }

                        widget.onSave(
                          widget.controller.text,
                          _descriptionController.text,
                          finalDateTimes,
                          _selectedReminderType,
                          _selectedReminderType == ReminderType.option ? _options : null,
                          _selectedReminderType == ReminderType.answerBack
                              ? _expectedAnswerController.text
                              : null,
                          _selectedReminderType == ReminderType.aiPrompt
                              ? _aiPromptController.text
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Buttonstyl(
                      savetext: 'Cancel',
                      onPressed: widget.onCancel,
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
