import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';

class GoalStepDialogBox extends ConsumerWidget {
  final TextEditingController controller;
  final String? initialStepText;
  final VoidCallback onCancel;
  final Function(String stepText) onSave;

  const GoalStepDialogBox({
    super.key,
    required this.controller,
    this.initialStepText,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return AlertDialog(
      backgroundColor: appTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: appTheme.background,
        ),
        child: Column(
          children: [
            // Title
            Text(
              initialStepText == null ? 'Add New Step' : 'Edit Step',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appTheme.primary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Step input
            TextField(
              maxLength: 100,
              controller: controller,
              cursorColor: appTheme.primary,
              style: TextStyle(color: appTheme.primary),
              decoration: InputDecoration(
                hintText: 'Enter step description',
                hintStyle: TextStyle(color: appTheme.primary.withOpacity(0.6)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: appTheme.primary),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: appTheme.primary.withOpacity(0.3)),
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: appTheme.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Save button
                Buttonstyl(
                  savetext: initialStepText == null ? 'Add Step' : 'Save',
                  onPressed: () {
                    final stepText = controller.text.trim();
                    if (stepText.isNotEmpty) {
                      onSave(stepText);
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}