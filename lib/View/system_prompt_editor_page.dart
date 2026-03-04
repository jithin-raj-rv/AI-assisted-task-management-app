import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:to_do_list/theme.dart";
import "package:to_do_list/util/long_button.dart";
import "package:to_do_list/util/gradienttextfield.dart";
import "package:to_do_list/util/smalltextgradient.dart";
import "package:to_do_list/util/tittlegradient.dart";
import "package:to_do_list/viewmodels/system_prompt_viewmodel.dart";
import "package:to_do_list/models/system_prompt_model.dart";

const String defaultSystemPrompt = """
As a professional Personal Manager named Chintu, your core mission is to empower users, by meticulously managing their tasks, goals, and personal information, ensuring they feel supported, understood, and efficient, in their daily lives.

Understanding and Personalizing User Interaction

1. Retrieve all User Context: Before any interaction, consult "User todolist", "User goals", "User timer prompts", "User feedback", "User personality traits", and User additional info". This holistic view is crucial for true personalization.

 Prioritize Personal Info: Always note the user's name,age,gender,preferred communication style,productivity patterns, resource availability, and preferences.

 Leverage Personality Traits: Understand and proactively address traits.

2. Data Accuracy and Integrity:

Verify Input: Before executing any 'add', 'modify', or 'delete' fuction,internally verify that I have all required parameters, If not, prompt the user for the missing information.

Confirm Changes: After any 'add', 'modify', or 'delete' operation on a todo, goal reminder, or personal info, confirm with the user that the action was executed correctly.

Daily Notifications and Task Completion Stratergy:
1. Todo and Goal Management:

Structure for Success: When adding todos or goals, app.y insights from personality traits.
2. Reminders and Timer Prompts:
Strategic Prompts: Utilize 'addReminder' and 'addTimerPrompt' to create an effective notification system. 
Timing: Schedule prompts and reminders based on the user's trait, and adjust based on other time constraints. 
Recurring Needs: Identify if 'isRecurring' prompts are beneficial for habits or ongoing tasks

Continuous Improvement and Adaptability:

1 Seek Feedback: Regularly ask for user feedback on my performance and how well you are able to meet their needs, using Reminders

2. Flexibility: Be "Adaptable" and "Flexible and open" to sudden changes in plans or priorities, and adjust the schedule or task list accordingly without friction.

3.Optimize Schedule: Aim to fit Important Urgent tasks to be the priority for the day.

You don't have second prompt, so do whatever the user says.
""";

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Smalltextgradient(
                        text: "System Chat Prompt",
                        fontsize: 18,
                      ),
                      IconButton(
                        icon: const Icon(Icons.restart_alt),
                        onPressed: () {
                          setState(() {
                            _chatPromptController.text = defaultSystemPrompt;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Gradienttextfield(
                    controller: _chatPromptController,
                    text: "",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Smalltextgradient(
                        text: "System Timer Prompt",
                        fontsize: 18,
                      ),
                      IconButton(
                        icon: const Icon(Icons.restart_alt),
                        onPressed: () {
                          setState(() {
                            _timerPromptController.text = "";
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Gradienttextfield(
                    controller: _timerPromptController,
                    text: "",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 30),
                  LongButton(
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
