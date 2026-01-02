import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart'; // Import the model

class RemainderDialogBox extends StatefulWidget {
  const RemainderDialogBox({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.initialDescription,
    this.initialReminderDate,
    this.initialReminderType = ReminderType.basic, // New
    this.initialOptions, // New
    this.initialExpectedAnswer, // New
    this.initialAiPrompt, // New
  });

  final TextEditingController controller;
  final String? initialDescription;
  final DateTime? initialReminderDate;
  final VoidCallback onCancel;
  final Function(
    String name,
    String description,
    List<DateTime> reminderDateTimes, // Changed to List
    ReminderType reminderType, // New
    List<String>? options, // New
    String? expectedAnswer, // New
    String? aiPrompt, // New
  ) onSave;

  final ReminderType initialReminderType; // New
  final List<String>? initialOptions; // New
  final String? initialExpectedAnswer; // New
  final String? initialAiPrompt; // New

  @override
  State<RemainderDialogBox> createState() => _RemainderDialogBoxState();
}

class _RemainderDialogBoxState extends State<RemainderDialogBox> {
  late TextEditingController _descriptionController;
  DateTime? _selectedReminderDate;
  TimeOfDay? _selectedTime;
  final List<DateTime> _scheduledDateTimes = []; // List to store multiple times

  // New state variables for reminder types
  late ReminderType _selectedReminderType;
  late TextEditingController _newOptionController;
  late List<String> _options;
  late TextEditingController _expectedAnswerController;
  late TextEditingController _aiPromptController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _selectedReminderDate = widget.initialReminderDate;
    if (_selectedReminderDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(_selectedReminderDate!);
      // If editing, add the initial date to the list so it's visible/editable
      // However, for better UX in edit mode, we might just want to show it in the pickers.
      // Let's keep the list empty initially unless we want to support multi-edit explicitly.
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
    return AlertDialog(
      backgroundColor: Colors.grey,
      content: Container(
        height: _selectedReminderType == ReminderType.option ? 550 : 450, // Dynamic height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                maxLength: 30,
                controller: widget.controller,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Reminder Title',
                  hintStyle: TextStyle(color: Colors.white),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),

              TextField(
                maxLength: 100,
                controller: _descriptionController,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: TextStyle(color: Colors.white),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedReminderDate == null
                          ? 'No reminder date selected'
                          : 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedReminderDate!)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text(
                      'Select Date',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'No time selected'
                          : 'Time: ${_selectedTime!.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context),
                    child: const Text(
                      'Select Time',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // Add Time Button
              ElevatedButton(
                onPressed: _addDateTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text("Add Date & Time"),
              ),

              // Display selected times
              if (_scheduledDateTimes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: _scheduledDateTimes.map((dateTime) {
                      return Chip(
                        label: Text(
                          DateFormat('MMM dd, HH:mm').format(dateTime),
                          style: const TextStyle(fontSize: 12),
                        ),
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
                  const Text('Reminder Type:', style: TextStyle(color: Colors.white)),
                  DropdownButton<ReminderType>(
                    value: _selectedReminderType,
                    dropdownColor: Colors.grey[700],
                    style: const TextStyle(color: Colors.white),
                    onChanged: (ReminderType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedReminderType = newValue;
                        });
                      }
                    },
                    items: ReminderType.values.map<DropdownMenuItem<ReminderType>>(
                      (ReminderType type) {
                        return DropdownMenuItem<ReminderType>(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Conditional UI for Option Reminders
              if (_selectedReminderType == ReminderType.option) ...[
                TextField(
                  controller: _newOptionController,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add an option',
                    hintStyle: const TextStyle(color: Colors.white),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _addOption,
                    ),
                  ),
                  onSubmitted: (_) => _addOption(),
                ),
                if (_options.isNotEmpty)
                  Column(
                    children: _options.asMap().entries.map((entry) {
                      int index = entry.key;
                      String option = entry.value;
                      return ListTile(
                        title: Text(option, style: const TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeOption(index),
                        ),
                      );
                    }).toList(),
                  ),
              ],

              // Conditional UI for Answer Back Reminders
              if (_selectedReminderType == ReminderType.answerBack)
                TextField(
                  controller: _expectedAnswerController,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Expected Answer (optional)',
                    hintStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),

              // Conditional UI for AI Prompt Reminders
              if (_selectedReminderType == ReminderType.aiPrompt)
                TextField(
                  controller: _aiPromptController,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'AI Prompt (e.g., Give me a quote)',
                    hintStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),

              const SizedBox(height: 20), // Add some spacing

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Buttonstyl(
                    savetext: 'Save',
                    onPressed: () {
                      if (_selectedReminderType == ReminderType.option &&
                          _newOptionController.text.trim().isNotEmpty) {
                        _options.add(_newOptionController.text.trim());
                      }

                      // Prepare the list of dates to save
                      List<DateTime> finalDateTimes = List.from(_scheduledDateTimes);

                      // If the list is empty, try to use the currently selected values in the pickers
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
                         finalDateTimes.add(dt);
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
                  Buttonstyl(
                    savetext: 'Cancel',
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}