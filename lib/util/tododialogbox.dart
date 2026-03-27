import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/gradienttextfield.dart';
import 'package:to_do_list/util/selectbutton.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

class TodoDialogbox extends ConsumerStatefulWidget {
  const TodoDialogbox({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.initialImportance = false,
    this.initialUrgency = false,
    this.initialDescription,
    this.initialDueDate,
  });

  final TextEditingController controller;
  final String? initialDescription;
  final DateTime? initialDueDate;
  final VoidCallback onCancel;
  final Future<void> Function(
    String name,
    String description,
    DateTime? dueDate,
    bool isImportant,
    bool isUrgent,
  ) onSave;

  final bool initialImportance;
  final bool initialUrgency;

  @override
  ConsumerState<TodoDialogbox> createState() => _TodoDialogboxState();
}

/// Shows the styled todo dialog
Future<void> showTodoDialog({
  required BuildContext context,
  String? existingTaskName,
  String? existingDescription,
  DateTime? existingDueDate,
  bool existingImportance = false,
  bool existingUrgency = false,
  required Future<void> Function(
    String name,
    String description,
    DateTime? dueDate,
    bool isImportant,
    bool isUrgent,
  ) onSave,
}) async {
  final TextEditingController controller = TextEditingController(text: existingTaskName);
  
  await showDialog(
    context: context,
    builder: (context) => TodoDialogbox(
      controller: controller,
      initialDescription: existingDescription,
      initialDueDate: existingDueDate,
      initialImportance: existingImportance,
      initialUrgency: existingUrgency,
      onSave: onSave,
      onCancel: () => Navigator.of(context).pop(),
    ),
  );
}

class _TodoDialogboxState extends ConsumerState<TodoDialogbox> {
  late bool _isImportant;
  late bool _isUrgent;
  late TextEditingController _descriptionController;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _isImportant = widget.initialImportance;
    _isUrgent = widget.initialUrgency;
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _selectedDueDate = widget.initialDueDate?.toLocal();
    if (_selectedDueDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(_selectedDueDate!);
  }
}

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
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

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return AlertDialog(
      scrollable: true,
      backgroundColor: appTheme.background,
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Gradienttextfield(controller: widget.controller, text: "Task Name"),
          ),
      
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Gradienttextfield(controller: _descriptionController, text: "Description (optionsl)"),
          ),
      
          Row(
            children: [
              Expanded(
                child: Smalltextgradient(
                  fontsize: 15,
                  text: 
                  _selectedDueDate == null
                      ? 'No due date selected'
                      : 'Due Date: ${DateFormat('MMM dd, yyyy').format(_selectedDueDate!)}'
                ),
              ),
              TextButton(
                onPressed: () => _selectDate(context),
                child: const Smalltextgradient(
                  text:'Select Date',
                  fontsize: 15,
                ),
              ),
            ],
          ),
      
          Row(
            children: [
              Expanded(
                child: Smalltextgradient(
                  text:_selectedTime == null
                      ? 'No time selected'
                      : 'Time: ${_selectedTime!.format(context)}',
                  fontsize: 15,
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
      
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Selectbutton(
              initialSelection: _isImportant,
              text1: "IMPORTANT",
              text2: "NOT IMPORTANT",
              onSelectionChanged: (value) {
                setState(() => _isImportant = value);
              },
            ),
          ),
      
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Selectbutton(
              initialSelection: _isUrgent,
              text1: "URGENT",
              text2: "NOT URGENT",
              onSelectionChanged: (value) {
                setState(() => _isUrgent = value);
              },
            ),
          ),
      SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40,),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Buttonstyl(
                  savetext: 'Save',
                  onPressed: () async {
                    final taskName = widget.controller.text.trim();
                    if (taskName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a task name')),
                      );
                      return;
                    }

                    DateTime? finalDueDate;
                    if (_selectedDueDate != null) {
                      if (_selectedTime != null) {
                        finalDueDate = DateTime(
                          _selectedDueDate!.year,
                          _selectedDueDate!.month,
                          _selectedDueDate!.day,
                          _selectedTime!.hour,
                          _selectedTime!.minute,
                        );
                      } else {
                        finalDueDate = DateTime(
                          _selectedDueDate!.year,
                          _selectedDueDate!.month,
                          _selectedDueDate!.day,
                        );
                      }
                    }
                  
                    await widget.onSave(
                      taskName,
                      _descriptionController.text,
                      finalDueDate,
                      _isImportant,
                      _isUrgent,
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
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
    );
  }
}
