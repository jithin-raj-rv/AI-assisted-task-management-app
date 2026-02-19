import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/foreground_task_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/View/personalitypage.dart';
import 'package:to_do_list/View/additionalinfopage.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/main.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isRunningService = false;

  @override
  void initState() {
    super.initState();
    _initServiceState();
  }

  Future<void> _initServiceState() async {
    try {
      final running = await FlutterForegroundTask.isRunningService;
      if (mounted) setState(() => _isRunningService = running);
    } catch (e) {
      // If the plugin API differs, default to false
      if (mounted) setState(() => _isRunningService = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider).background == Colors.black; // Simple check for dark mode
    final appTheme = ref.watch(themeProvider);

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
          SwitchListTile(
            title: const Text('Background Reminder Monitoring'),
            subtitle: const Text('Show persistent notification for reminder alerts'),
            value: _isRunningService,
            onChanged: (value) async {
              if (value) {
                try {
                  await FlutterForegroundTask.startService(
                    notificationTitle: 'Todo App Active',
                    notificationText: 'Monitoring your reminders in background',
                    callback: startCallback,
                    notificationButtons: [NotificationButton(id: 'stop', text: 'Stop')],
                  );
                  if (mounted) setState(() => _isRunningService = true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Background monitoring enabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to start foreground service: $e')),
                    );
                  }
                  if (mounted) setState(() => _isRunningService = false);
                }
              } else {
                try {
                  await FlutterForegroundTask.stopService();
                  if (mounted) setState(() => _isRunningService = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Background monitoring disabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to stop foreground service: $e')),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            title: const Text('Request Notification Permission'),
            subtitle: const Text('Ask the OS to allow notifications (Android 13+)'),
            onTap: () async {
              try {
                final granted = await localNotificationService.requestPermission();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(granted == true ? 'Notifications allowed' : 'Notifications denied or not supported')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Permission request failed: $e')),
                  );
                }
              }
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
          ListTile(
            title: const Text('Personality'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PersonalityPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Additional Information'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdditionalInfoPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () async {
              final viewModel = ref.read(settingsPageViewModelProvider.notifier);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                await viewModel.logout();
                // Navigation back to login will be handled automatically by AuthWrapper
              }
            },
          ),
        ],
      ),
    );
  }


}
