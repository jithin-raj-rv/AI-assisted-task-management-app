import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
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
import 'package:to_do_list/Notification/notification_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    try {
      await _notificationService.init();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Failed to initialize notification service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider).background == Colors.black;
    final appTheme = ref.watch(themeProvider);
    final foregroundServiceManager =
        ref.watch(foregroundServiceManagerProvider);
    final serviceRunningAsync = ref.watch(foregroundServiceRunningProvider);
    final isServiceRunning = serviceRunningAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: 'Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (value) {
              themeNotifier.toggleTheme();
            },
          ),
          SwitchListTile(
            title: const Text('Background Reminder Monitoring'),
            subtitle:
                const Text('Show persistent notification for reminder alerts'),
            value: isServiceRunning,
            onChanged: (value) async {
              if (value) {
                // First request battery optimization exemption for reliable background alarms
                await foregroundServiceManager.requestBatteryOptimizationExemption();
              }
              await foregroundServiceManager.setServiceEnabled(value);
              if (mounted) {
                ref.invalidate(foregroundServiceRunningProvider);
              }
            },
          ),
          if (!isServiceRunning)
            ListTile(
              title: const Text('Disable Battery Optimization'),
              subtitle: const Text(
                  'Required for reliable background reminders (opens settings)'),
              onTap: () async {
                await foregroundServiceManager.requestBatteryOptimizationExemption();
              },
            ),
          if (isServiceRunning)
            ListTile(
              title: const Text('Stop Background Service'),
              subtitle:
                  const Text('Force stop the background reminder service'),
              onTap: () async {
                await foregroundServiceManager.stopService();
                if (mounted) {
                  ref.invalidate(foregroundServiceRunningProvider);
                }
              },
            ),
          ListTile(
            title: const Text('Request Notification Permission'),
            subtitle:
                const Text('Ask the OS to allow notifications (Android 13+)'),
            onTap: () async {
              try {
                final granted =
                    await _notificationService.requestNotificationPermission();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(granted == true
                            ? 'Notifications allowed'
                            : 'Notifications denied or not supported')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Permission request failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text(
                'This will delete all your tasks, goals, personality, and additional info.'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Clear Data'),
                    content: const Text(
                        'Are you sure you want to delete all your data? This action cannot be undone.'),
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
                await Hive.box<Todo>('todos').clear();
                await Hive.box<Goal>('goals').clear();
                await Hive.box<TimerPrompt>('timer_prompts').clear();
                await Hive.box<ScheduledNotification>('scheduled_notifications')
                    .clear();
                await Hive.box<UserFeedback>('user_feedback').clear();
                await Hive.box('settings').clear();
                await Hive.box('boxx').clear();
                await Hive.box('questionBox').clear();
                await Hive.box('userResponsesBox').clear();

                if (mounted) {
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
                MaterialPageRoute(
                    builder: (context) => const PersonalityPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Additional Information'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdditionalInfoPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () async {
              final viewModel =
                  ref.read(settingsPageViewModelProvider.notifier);
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
              }
            },
          ),
        ],
      ),
    );
  }
}
