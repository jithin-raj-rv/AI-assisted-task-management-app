import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:to_do_list/util/button.dart";
import "package:to_do_list/util/gradienttextfield.dart";
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

    if (systemPromptState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (systemPromptState.systemPrompts.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No system prompt found."),
        ),
      );
    }

    final systemPrompt = systemPromptState.systemPrompts.first;
    _chatPromptController.text = systemPrompt.systemChatPrompt;
    _timerPromptController.text = systemPrompt.systemTimerPrompt;

    return Scaffold(
      appBar: AppBar(
        title: const Tittlegradient(text: "System Prompts"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Gradienttextfield(
                controller: _chatPromptController,
                text: "System Chat Prompt",
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              Gradienttextfield(
                controller: _timerPromptController,
                text: "System Timer Prompt",
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
    );
  }
}
