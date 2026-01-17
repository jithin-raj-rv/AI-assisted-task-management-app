import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/Notification/local_notification_service.dart';
import 'package:to_do_list/View/homepage.dart';
import 'package:to_do_list/View/login_page.dart';
import 'package:to_do_list/View/user_info_collection_page.dart';
import 'package:to_do_list/View/onboarding_dialog.dart';
import 'package:to_do_list/View/chatscreen.dart';
import 'package:to_do_list/models/user_info_collection.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart'; // Import the new scheduled notification model
import 'package:to_do_list/models/timer_prompt_model.dart'; // Import the new timer prompt model
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/models/personality_trait_model.dart';
import 'package:to_do_list/models/additional_info_model.dart';
import 'package:to_do_list/viewmodels/timer_prompt_viewmodel.dart';
import 'package:to_do_list/cache/timer_prompt_cache.dart';
import 'package:to_do_list/cache/todo_cache.dart';
import 'package:to_do_list/cache/goal_cache.dart';
import 'package:to_do_list/cache/scheduled_notification_cache.dart';
import 'package:to_do_list/cache/personality_cache.dart';
import 'package:to_do_list/cache/additional_info_cache.dart';
import 'package:to_do_list/providers.dart'; // Import providers
import 'package:to_do_list/sync_providers.dart'; // Import sync providers
import 'package:to_do_list/services/connectivity_service.dart'; // Import connectivity service
import 'package:to_do_list/config/supabase_config.dart';

final localNotificationService = LocalNotificationService();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> onNotificationResponse(String? payload) async {
  print("Notification response received with payload: $payload");
  if (payload != null && payload.startsWith('timer_prompt_')) {
    final parts = payload.split('_');
    if (parts.length >= 3) {
      final promptId = parts[2];
      print("Extracted promptId from notification: $promptId");
      // Find the prompt text from the local cache
      final prompt = await TimerPromptCache().get(promptId) ?? TimerPrompt(id: '', prompt: '', scheduledTime: DateTime.now());

      if (prompt.prompt.isNotEmpty && navigatorKey.currentContext != null) {
        print("Showing timer prompt dialog for prompt: ${prompt.prompt}");
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) => TimerPromptExecutionDialog(prompt: prompt),
        );
      } else {
        print("Prompt not found or navigator not available");
      }
    }
  }
}

Future<void> migrateData() async {
  final todosBox = Hive.box<Todo>('todos');
  final goalsBox = Hive.box<Goal>('goals');
  final timerPromptsBox = Hive.box<TimerPrompt>('timer_prompts');
  final scheduledNotificationsBox = Hive.box<ScheduledNotification>('scheduled_notifications');
  final userFeedbackBox = Hive.box<UserFeedback>('user_feedback');
  final settingsBox = Hive.box('settings');

  // Only migrate if typed boxes are empty
  if (todosBox.isNotEmpty || goalsBox.isNotEmpty || timerPromptsBox.isNotEmpty ||
      scheduledNotificationsBox.isNotEmpty || userFeedbackBox.isNotEmpty) {
    print("Migration skipped: Typed boxes already contain data.");
    return;
  }

  final oldBox = Hive.box('boxx');

  // Migrate todos
  final rawTodoList = oldBox.get("TODOLIST") as List<dynamic>? ?? [];
  for (int i = 0; i < rawTodoList.length; i++) {
    final todo = Todo.fromHiveList(rawTodoList[i] as List<dynamic>);
    todo.id ??= i.toString();
    await todosBox.put(todo.id!, todo);
  }

  // Migrate goals
  final rawGoals = oldBox.get("GOALS") as List<dynamic>? ?? [];
  for (var item in rawGoals) {
    final goal = Goal.fromHiveList(item as List<dynamic>);
    await goalsBox.put(goal.title, goal); // Using title as key
  }

  // Migrate timer prompts
  final rawTimerPrompts = oldBox.get("TIMER_PROMPTS") as List<dynamic>? ?? [];
  for (var item in rawTimerPrompts) {
    final prompt = TimerPrompt.fromHiveList(item as List<dynamic>);
    await timerPromptsBox.put(prompt.id, prompt);
  }

  // Migrate scheduled notifications
  final rawScheduledNotifications = oldBox.get("SCHEDULED_NOTIFICATIONS") as List<dynamic>? ?? [];
  for (var item in rawScheduledNotifications) {
    final notification = ScheduledNotification.fromHiveList(item as List<dynamic>);
    await scheduledNotificationsBox.put(notification.id, notification);
  }

  // Migrate user feedback
  final rawUserFeedback = oldBox.get("USER_FEEDBACK") as List<dynamic>? ?? [];
  for (var item in rawUserFeedback) {
    final feedback = UserFeedback.fromHiveList(item as List<dynamic>);
    await userFeedbackBox.put(feedback.timestamp.millisecondsSinceEpoch, feedback); // Using timestamp as key
  }

  // Migrate settings
  final personality = oldBox.get("PERSONALITY") ?? [];
  final additionalinfo = oldBox.get("ADDITIONALINFO") ?? [];
  await settingsBox.put("personality", personality);
  await settingsBox.put("additional_info", additionalinfo);

  print("Migration completed successfully.");
}

Future<void> rescheduleNotifications() async {
  final scheduledNotificationsBox = Hive.box<ScheduledNotification>('scheduled_notifications');
  final notifications = scheduledNotificationsBox.values.toList();
  await localNotificationService.rescheduleAllNotifications(notifications);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized

  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(ScheduledNotificationAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  Hive.registerAdapter(TimerPromptAdapter());
  Hive.registerAdapter(UserFeedbackAdapter());
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(QuestionTypeAdapter());
  Hive.registerAdapter(PersonalityTraitAdapter());
  Hive.registerAdapter(AdditionalInfoAdapter());



  // Open typed boxes
  await Hive.openBox<Todo>('todos');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<TimerPrompt>('timer_prompts');
  await Hive.openBox<ScheduledNotification>('scheduled_notifications');
  await Hive.openBox<UserFeedback>('user_feedback');
  await Hive.openBox<PersonalityTrait>('personality_traits');
  await Hive.openBox<AdditionalInfo>('additional_info_items');
  await Hive.openBox('settings');

  // Keep old box for migration
  await Hive.openBox('boxx');
  await Hive.openBox('questionBox');
  await Hive.openBox('userResponsesBox');

  // Migrate data from old box to typed boxes
  await migrateData();

  // Initialize notification service
  // Pass the handler to the init method (ensure your LocalNotificationService supports this)
  await localNotificationService.init(onNotificationResponse: onNotificationResponse);

  // Reschedule notifications (must be after init to ensure timezone is initialized)
  await rescheduleNotifications();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Listen to auth state changes to (re)attach realtime subscriptions reliably
  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    final user = event.session?.user;
    if (user != null) {
      // Realtime setup will be handled by AuthWrapper via providers
      print('[AuthListener] User signed in');
    } else {
      // Clear realtime if needed, but DataSyncService handles it
      print('[AuthListener] User signed out');
    }
  });

  runApp(const ProviderScope(child: MyApp()));
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure AuthStateManager is active and listening to auth changes
    ref.watch(authStateManagerProvider);

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (data) {
        if (data.session != null) {
          final syncState = ref.watch(dataSyncProvider);

          return syncState.when(
            data: (_) => const Homepage(),
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, _) => Scaffold(body: Center(child: Text('Sync Error: $e'))),
          );
        } else {
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Auth Error: $error'))),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: appTheme.isDarkMode
          ? ThemeData.dark().copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: appTheme.background,
                foregroundColor: appTheme.primaryGradient1,
                titleTextStyle: const TextStyle(fontSize: 40,color: Colors.white),
              ),
              scaffoldBackgroundColor: appTheme.background, // Set background for dark mode
            )
          : ThemeData.light().copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: appTheme.background,
                foregroundColor: appTheme.primaryGradient1,
                titleTextStyle: const TextStyle(fontSize: 40, color: Colors.white),
                
              ),
              scaffoldBackgroundColor: appTheme.background, // Set background for light mode
            ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return Homepage(
              initialPage: args['page'] as int? ?? 0,
              initialPrompt: args['prompt'] as String?,
            );
          } else if (args is int) {
            return Homepage(initialPage: args);
          } else {
            return const Homepage();
          }
        },
        '/login': (context) => const LoginPage(),
        '/userInfoCollection': (context) => const UserInfoCollectionPage(),
        '/chat': (context) => ChatScreen(initialPrompt: ModalRoute.of(context)!.settings.arguments as String?),
      },
    );
  }
}


class TimerPromptExecutionDialog extends ConsumerStatefulWidget {
  final TimerPrompt prompt;
  const TimerPromptExecutionDialog({super.key, required this.prompt});

  @override
  ConsumerState<TimerPromptExecutionDialog> createState() => _TimerPromptExecutionDialogState();
}

class _TimerPromptExecutionDialogState extends ConsumerState<TimerPromptExecutionDialog> {
  String? _response;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _executePrompt();
  }

  Future<void> _executePrompt() async {
    try {
      // Execute via the TimerPrompt ViewModel
      await ref.read(timerPromptViewModelProvider.notifier).executePrompt(widget.prompt);

      // Get the updated response from the prompt (read from ViewModel state)
      final promptsState = ref.read(timerPromptViewModelProvider);
      TimerPrompt? p;
      try {
        p = promptsState.prompts.firstWhere((e) => e.id == widget.prompt.id);
      } catch (err) {
        p = null;
      }
      if (p != null) {
        _response = p.response?.split('\n\n').first ?? 'No response';
      } else {
        _response = 'Prompt not found';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _response = "Error executing prompt: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.prompt.prompt),
      content: _isLoading 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(child: Text(_response ?? '')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
