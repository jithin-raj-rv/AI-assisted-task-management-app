import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/util/button.dart';

class Goaldialogbox extends StatefulWidget {
  const Goaldialogbox({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.initialDescription,
    this.initialTargetDate,
  });

  final TextEditingController controller;
  final String? initialDescription;
  final DateTime? initialTargetDate;
  final VoidCallback onCancel;
  final Function(
    String name,
    String description,
    DateTime? dueDate,
    bool isCompleted,
  ) onSave;


  @override
  State<Goaldialogbox> createState() => _DialogboxState();
}

class _DialogboxState extends State<Goaldialogbox> {
  late TextEditingController _descriptionController;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _selectedDueDate = widget.initialTargetDate;
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
                hintText: 'Goal Name',
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Buttonstyl(
                  savetext: 'Save',
                  onPressed: () => widget.onSave(
                    widget.controller.text,
                    _descriptionController.text,
                    _selectedDueDate,
                    false,
                  ),
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
