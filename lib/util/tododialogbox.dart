import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/selectbutton.dart';

class TodoDialogbox extends StatefulWidget {
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
  final Function(
    String name,
    String description,
    DateTime? dueDate,
    bool isImportant,
    bool isUrgent,
  ) onSave;

  final bool initialImportance;
  final bool initialUrgency;

  @override
  State<TodoDialogbox> createState() => _TodoDialogboxState();
}

class _TodoDialogboxState extends State<TodoDialogbox> {
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
    _selectedDueDate = widget.initialDueDate;
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
    return AlertDialog(
      backgroundColor: Colors.grey,
      content: Container(
        height: 420,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey,
        ),
        child: Column(
          children: [
            TextField(
              maxLength: 30,
              controller: widget.controller,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Task Name',
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
                    _selectedDueDate == null
                        ? 'No due date selected'
                        : 'Due Date: ${DateFormat('MMM dd, yyyy').format(_selectedDueDate!)}',
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

            Padding(
              padding: const EdgeInsets.all(8.0),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Buttonstyl(
                  savetext: 'Save',
                  onPressed: () {
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

                    widget.onSave(
                      widget.controller.text,
                      _descriptionController.text,
                      finalDueDate,
                      _isImportant,
                      _isUrgent,
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
    );
  }
}
