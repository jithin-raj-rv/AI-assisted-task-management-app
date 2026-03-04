import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/gradienttextfield.dart';
import 'package:to_do_list/util/selectbutton.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

class Goaldialogbox extends ConsumerStatefulWidget {
  const Goaldialogbox({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.initialDescription,
    this.initialTargetDate,
    this.initialImportance = false,
    this.initialUrgency = false,
  });

  final TextEditingController controller;
  final String? initialDescription;
  final DateTime? initialTargetDate;
  final bool initialImportance;
  final bool initialUrgency;
  final VoidCallback onCancel;
  final Function(
    String name,
    String description,
    DateTime? dueDate,
    bool isCompleted,
    String importance,
    String urgency,
  ) onSave;

  @override
  ConsumerState<Goaldialogbox> createState() => _GoaldialogboxState();
}

class _GoaldialogboxState extends ConsumerState<Goaldialogbox> {
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
    _selectedDueDate = widget.initialTargetDate;
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
            child: Gradienttextfield(controller: widget.controller, text: "Goal Name"),
          ),
      
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Gradienttextfield(controller: _descriptionController, text: "Description (optional)"),
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
                    
                    final importance = _isImportant ? 'IMPORTANT' : 'NOT IMPORTANT';
                    final urgency = _isUrgent ? 'URGENT' : 'NOT URGENT';
                  
                    widget.onSave(
                      widget.controller.text,
                      _descriptionController.text,
                      finalDueDate,
                      false,
                      importance,
                      urgency,
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
    );
  }
}
