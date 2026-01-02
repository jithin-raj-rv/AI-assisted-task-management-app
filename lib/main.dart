import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/Notification/local_notification_service.dart';
import 'package:to_do_list/View/homepage.dart';
import 'package:to_do_list/View/login_page.dart';
import 'package:to_do_list/database/database.dart';
import 'package:to_do_list/models/user_info_collection.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart'; // Import the new scheduled notification model
import 'package:to_do_list/models/timer_prompt_model.dart'; // Import the new timer prompt model
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/View Model/timer_prompt_vm.dart'; // Import the new function
import 'package:to_do_list/Timer prompt send/timerpromptsender.dart'; // Import timer prompt sender
import 'package:to_do_list/providers.dart'; // Import providers
import 'package:to_do_list/config/supabase_config.dart';
import 'package:workmanager/workmanager.dart';

final localNotificationService = LocalNotificationService();
final Localdata db = Localdata(localNotificationService); // Initialize db with localNotificationService

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void onNotificationResponse(String? payload) {
  print("Notification response received with payload: $payload");
  if (payload != null && payload.startsWith('timer_prompt_')) {
    final parts = payload.split('_');
    if (parts.length >= 3) {
      final promptId = parts[2];
      print("Extracted promptId from notification: $promptId");
      // Find the prompt text from the database
      final prompt = db.timerPrompts.firstWhere(
        (p) => p.id == promptId,
        orElse: () => TimerPrompt(id: '', prompt: '', scheduledTime: DateTime.now()),
      );

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
  Hive.registerAdapter(TimerPromptAdapter());
  Hive.registerAdapter(UserFeedbackAdapter());
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(QuestionTypeAdapter());

  // Open typed boxes
  await Hive.openBox<Todo>('todos');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<TimerPrompt>('timer_prompts');
  await Hive.openBox<ScheduledNotification>('scheduled_notifications');
  await Hive.openBox<UserFeedback>('user_feedback');
  await Hive.openBox('settings');

  // Keep old box for migration
  await Hive.openBox('boxx');
  await Hive.openBox('questionBox');
  await Hive.openBox('userResponsesBox');

  // Migrate data from old box to typed boxes
  await migrateData();

  // Load Localdata lists from the legacy untyped box so global `db` has current data
  db.loaddata();

  // Reschedule notifications
  await rescheduleNotifications();

  // Initialize notification service
  // Pass the handler to the init method (ensure your LocalNotificationService supports this)
  await localNotificationService.init(onNotificationResponse: onNotificationResponse);

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // set false in release
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // After Supabase is initialized, pull user data and set up realtime subscriptions
  await db.syncFromSupabase();
  db.setupRealtimeSubscriptions();

  runApp(const ProviderScope(child: MyApp()));
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (data) {
        if (data.session != null) {
          return const Homepage();
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
    // Workmanager().registerOneOffTask(
    //   "aiTask",
    //   "sendGeminiPrompt",
    //   inputData: {
    //     "prompt": "Generate today's optimal task plan",
    //   },
    // );
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
        '/home': (context) => const Homepage(),
        '/login': (context) => const LoginPage(),
        '/userInfoCollection': (context) => const Homepage(),
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
      // Use the new executeTimerPrompt function
      await executeTimerPrompt(ref, widget.prompt);

      // Get the updated response from the prompt
      final repo = ref.read(timerPromptsRepositoryProvider);
      final p = repo.getTimerPrompt(widget.prompt.id);
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
