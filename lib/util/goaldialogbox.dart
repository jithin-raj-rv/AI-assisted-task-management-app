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
    this.initialImportance = false,
    this.initialUrgency = false,
  });

  final TextEditingController controller;
  final String? initialDescription;
  final bool initialImportance;
  final bool initialUrgency;
  final VoidCallback onCancel;
  final Future<void> Function(
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

/// Shows the styled goal dialog
Future<void> showGoalDialog({
  required BuildContext context,
  String? existingGoalName,
  String? existingDescription,
  bool existingImportance = false,
  bool existingUrgency = false,
  required Future<void> Function(
    String name,
    String description,
    DateTime? dueDate,
    bool isCompleted,
    String importance,
    String urgency,
  ) onSave,
}) async {
  final TextEditingController controller = TextEditingController(text: existingGoalName);
  
  await showDialog(
    context: context,
    builder: (context) => Goaldialogbox(
      controller: controller,
      initialDescription: existingDescription,
      initialImportance: existingImportance,
      initialUrgency: existingUrgency,
      onSave: onSave,
      onCancel: () => Navigator.of(context).pop(),
    ),
  );
}

class _GoaldialogboxState extends ConsumerState<Goaldialogbox> {
  late bool _isImportant;
  late bool _isUrgent;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _isImportant = widget.initialImportance;
    _isUrgent = widget.initialUrgency;
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
                    final goalName = widget.controller.text.trim();
                    if (goalName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a goal name')),
                      );
                      return;
                    }

                    final importance = _isImportant ? 'IMPORTANT' : 'NOT IMPORTANT';
                    final urgency = _isUrgent ? 'URGENT' : 'NOT URGENT';
                  
                    await widget.onSave(
                      goalName,
                      _descriptionController.text,
                      null,
                      false,
                      importance,
                      urgency,
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
