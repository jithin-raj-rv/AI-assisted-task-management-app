import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/button.dart';
import 'package:to_do_list/util/selectbutton.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

class SystemDialogBox extends ConsumerWidget {
  final TextEditingController controller;
  final String? initialStepText;
  final VoidCallback onCancel;
  final Function(String stepText) onSave;

  const SystemDialogBox({
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
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: appTheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(
          minHeight: 220,
          maxHeight: 400,
          minWidth: 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appTheme.background.withOpacity(0.9),
              appTheme.background.withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: appTheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    appTheme.actionGradientStart.withOpacity(0.1),
                    appTheme.actionGradientEnd.withOpacity(0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: appTheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          appTheme.actionGradientStart.withOpacity(0.3),
                          appTheme.actionGradientEnd.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      initialStepText == null ? Icons.add_circle : Icons.edit,
                      color: appTheme.primary,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title
                  Expanded(
                    child: Text(
                      initialStepText == null ? 'Add New System' : 'Edit System',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: appTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    Text(
                      initialStepText == null 
                        ? 'Create a new system to organize your workflow' 
                        : 'Update your system details',
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.primary.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // System input with modern styling
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            appTheme.primary.withOpacity(0.05),
                            appTheme.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: appTheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        maxLength: 100,
                        controller: controller,
                        cursorColor: appTheme.primary,
                        style: TextStyle(
                          color: appTheme.primary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter system description',
                          hintStyle: TextStyle(
                            color: appTheme.primary.withOpacity(0.5),
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          suffixIcon: controller.text.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${controller.text.length}/100',
                                  style: TextStyle(
                                    color: appTheme.primary.withOpacity(0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : null,
                        ),
                        maxLines: 4,
                        minLines: 2,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    appTheme.background.withOpacity(0.0),
                    appTheme.background.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button with modern styling
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: appTheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: appTheme.primary.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Save button with enhanced styling
                  Buttonstyl(
                    onPressed: () {
                      final systemText = controller.text.trim();
                      if (systemText.isNotEmpty) {
                        onSave(systemText);
                        controller.clear();
                      }
                    },
                    savetext: initialStepText == null ? 'Add System' : 'Save Changes',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}