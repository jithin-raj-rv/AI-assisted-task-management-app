import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/gradienttextfield.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

class ToAchieveDialogBox extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? initialTitle;
  final DateTime? initialTargetDate;
  final VoidCallback onCancel;
  final void Function(String, DateTime?) onSave;

  const ToAchieveDialogBox({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.initialTitle,
    this.initialTargetDate,
  });

  @override
  ConsumerState<ToAchieveDialogBox> createState() => _ToAchieveDialogBoxState();
}

class _ToAchieveDialogBoxState extends ConsumerState<ToAchieveDialogBox> {
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDueDate = widget.initialTargetDate;
    if (_selectedDueDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(_selectedDueDate!);
    }
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
            child: Gradienttextfield(controller: widget.controller, text: "To Achieve Step"),
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

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40,),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Buttonstyl(
                  savetext: 'Save',
                  onPressed: () {
                    final title = widget.controller.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a step name')),
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

                    widget.onSave(title, finalDueDate);
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
