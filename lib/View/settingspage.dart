import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider).background == Colors.black; // Simple check for dark mode
    final settingsAsync = ref.watch(settingsProvider);
    final appTheme = ref.watch(themeProvider);

    return settingsAsync.when(
      data: (settings) {
        final personality = List<String>.from(settings['personality'] ?? []);
        final additionalInfo = List<String>.from(settings['additional_info'] ?? []);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appTheme.background,
            title: Tittlegradient(text: 'Settings')
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDarkMode,
                onChanged: (value) {
                  themeNotifier.toggleTheme(); // This method will be implemented in theme.dart
                },
              ),
              ListTile(
                title: const Text('Clear All Data'),
                subtitle: const Text('This will delete all your tasks, goals, personality, and additional info.'),
                onTap: () async {
                  // Show a confirmation dialog before clearing data
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Clear Data'),
                        content: const Text('Are you sure you want to delete all your data? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Clear'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    // Clear all data boxes
                    await Hive.box<Todo>('todos').clear();
                    await Hive.box<Goal>('goals').clear();
                    await Hive.box<TimerPrompt>('timer_prompts').clear();
                    await Hive.box<ScheduledNotification>('scheduled_notifications').clear();
                    await Hive.box<UserFeedback>('user_feedback').clear();
                    await Hive.box('settings').clear();
                    await Hive.box('boxx').clear(); // Also clear old box
                    await Hive.box('questionBox').clear();
                    await Hive.box('userResponsesBox').clear();

                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared!')),
                      );
                    }
                  }
                },
              ),
              ExpansionTile(
                title: const Text('Personality'),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: personality.length,
                    itemBuilder: (context, index) {
                      final item = personality[index];
                      return ListTile(
                        title: Text(item),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditDialog(context, item, (newValue) async {
                                  final updatedPersonality = List<String>.from(personality);
                                  updatedPersonality[index] = newValue;
                                  await Hive.box('settings').put('personality', updatedPersonality);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final updatedPersonality = List<String>.from(personality)..removeAt(index);
                                await Hive.box('settings').put('personality', updatedPersonality);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Add New Personality Trait'),
                    leading: const Icon(Icons.add),
                    onTap: () {
                      _showAddDialog(context, (newValue) async {
                        final updatedPersonality = List<String>.from(personality)..add(newValue);
                        await Hive.box('settings').put('personality', updatedPersonality);
                      });
                    },
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Additional Information'),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: additionalInfo.length,
                    itemBuilder: (context, index) {
                      final item = additionalInfo[index];
                      return ListTile(
                        title: Text(item),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditDialog(context, item, (newValue) async {
                                  final updatedAdditionalInfo = List<String>.from(additionalInfo);
                                  updatedAdditionalInfo[index] = newValue;
                                  await Hive.box('settings').put('additional_info', updatedAdditionalInfo);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final updatedAdditionalInfo = List<String>.from(additionalInfo)..removeAt(index);
                                await Hive.box('settings').put('additional_info', updatedAdditionalInfo);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Add New Additional Information'),
                    leading: const Icon(Icons.add),
                    onTap: () {
                      _showAddDialog(context, (newValue) async {
                        final updatedAdditionalInfo = List<String>.from(additionalInfo)..add(newValue);
                        await Hive.box('settings').put('additional_info', updatedAdditionalInfo);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading settings: $error'),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, Function(String) onSave) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Enter new item'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  onSave(_controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String currentText, Function(String) onSave) {
    final TextEditingController _controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Edit item'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  onSave(_controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
