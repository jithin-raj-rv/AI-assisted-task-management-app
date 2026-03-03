import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:to_do_list/theme.dart";
import "package:to_do_list/util/button.dart";
import "package:to_do_list/util/gradienttextfield.dart";
import "package:to_do_list/util/smalltextgradient.dart";
import "package:to_do_list/util/tittlegradient.dart";
import "package:to_do_list/viewmodels/system_prompt_viewmodel.dart";
import "package:to_do_list/models/system_prompt_model.dart";

class SystemPromptEditorPage extends ConsumerStatefulWidget {
  const SystemPromptEditorPage({super.key});

  @override
  ConsumerState<SystemPromptEditorPage> createState() =>
      _SystemPromptEditorPageState();
}

class _SystemPromptEditorPageState
    extends ConsumerState<SystemPromptEditorPage> {
  final _chatPromptController = TextEditingController();
  final _timerPromptController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final systemPromptState = ref.watch(systemPromptViewModelProvider);
    final appTheme = ref.watch(themeProvider);

    if (systemPromptState.isLoading) {
      return Scaffold(
        backgroundColor: appTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (systemPromptState.systemPrompts.isEmpty) {
      return Scaffold(
        backgroundColor: appTheme.background,
        body: const Center(
          child: Text("No system prompt found."),
        ),
      );
    }

    final systemPrompt = systemPromptState.systemPrompts.first;
    _chatPromptController.text = systemPrompt.systemChatPrompt;
    _timerPromptController.text = systemPrompt.systemTimerPrompt;

    return Scaffold(
      backgroundColor: appTheme.background,
      appBar: AppBar(
        title: const Tittlegradient(text: "System Prompts"),
        backgroundColor: appTheme.background,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: appTheme.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.primary.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Smalltextgradient(text: "System Chat Prompt",fontsize: 18,),
                  const SizedBox(height: 10),
                  Gradienttextfield(
                    controller: _chatPromptController,
                    text: "",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  const Smalltextgradient(text: "System Timer Prompt",fontsize:18),
                  const SizedBox(height: 10),
                  Gradienttextfield(
                    controller: _timerPromptController,
                    text: "",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 30),
                  Buttonstyl(
                    savetext: "Save",
                    onPressed: () {
                      final updatedPrompt = systemPrompt.copyWith(
                        systemChatPrompt: _chatPromptController.text,
                        systemTimerPrompt: _timerPromptController.text,
                      );
                      ref
                          .read(systemPromptViewModelProvider.notifier)
                          .updateSystemPrompt(updatedPrompt);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
