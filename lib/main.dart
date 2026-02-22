import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:to_do_list/Notification/local_notification_service.dart';
import 'package:to_do_list/foreground_task_handler.dart';
import 'package:to_do_list/View/homepage.dart';
import 'package:to_do_list/View/login_page.dart';
import 'package:to_do_list/View/user_info_collection_page.dart';
import 'package:to_do_list/View/onboarding_dialog.dart';
import 'package:to_do_list/View/chatscreen.dart';
import 'package:to_do_list/models/goal_step_model.dart';
import 'package:to_do_list/models/user_info_collection.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/models/personality_trait_model.dart';
import 'package:to_do_list/models/additional_info_model.dart';
import 'package:to_do_list/viewmodels/timer_prompt_viewmodel.dart';
import 'package:to_do_list/cache/timer_prompt_cache.dart';
import 'package:to_do_list/config/supabase_config.dart';
import 'package:to_do_list/services/supabase_gemini_service.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/services/foreground_service_manager.dart';

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
  Hive.registerAdapter(GoalStepAdapter());
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

  // Request notification permission (required for Android 13+)
  final bool? granted = await localNotificationService.requestPermission();
  if (granted != true) {
    print('Notification permission denied');
  } else {
    print('Notification permission granted');
    
    // Check if exact alarms can be scheduled
    final canScheduleExact = await localNotificationService.canScheduleExactNotifications();
    print('Can schedule exact notifications: $canScheduleExact');
    
    
  }

  // Reschedule notifications (must be after init to ensure timezone is initialized)
  // This should be called regardless of permission status to ensure existing notifications work
  await rescheduleNotifications();
  

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize foreground task for persistent background monitoring
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Todo App Background',
      channelDescription: 'App is running in background to monitor reminders',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(60000), // Check every 60 seconds
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // Initialize foreground service manager (restores service if was previously enabled)
  final foregroundServiceManager = ForegroundServiceManager();
  await foregroundServiceManager.init();

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

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _onboardingDialogShown = false; // Prevent duplicate onboarding dialogs

  @override
  Widget build(BuildContext context) {
    // Ensure AuthStateManager is active and listening to auth changes
    ref.watch(authStateManagerProvider);

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (data) {
        if (data.session != null) {
          final syncState = ref.watch(dataSyncProvider);

          return syncState.when(
            data: (_) {
              // After sync completes, check for onboarding
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final userHasData = ref.read(userHasDataProvider);
                _checkAndShowOnboarding(userHasData);
              });
              return const Homepage();
            },
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

  void _checkAndShowOnboarding(bool userHasData) {
    final allReady = ref.read(allViewModelsReadyProvider);
    if (!allReady) return; // Wait for all viewmodels to be ready

    // Prevent showing onboarding dialog multiple times in the same session
    if (_onboardingDialogShown) return;

    // Check if onboarding is already completed
    final settingsBox = Hive.box('settings');
    final onboardingCompleted = settingsBox.get('onboarding_completed', defaultValue: false);
    if (onboardingCompleted) return;

    print("Checking onboarding: allReady=$allReady, userHasData=$userHasData");
    if (!userHasData) {
      _onboardingDialogShown = true; // Mark as shown to prevent duplicates
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const OnboardingDialog(),
      );
    }
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to reschedule notifications when app resumes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('[AppLifecycle] App resumed - checking notifications');
      // Reschedule all notifications when app resumes
      localNotificationService.rescheduleAllNotifications(
        Hive.box<ScheduledNotification>('scheduled_notifications').values.toList(),
      );
    }
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
                foregroundColor: appTheme.actionGradientStart,
                titleTextStyle: const TextStyle(fontSize: 40,color: Colors.white),
              ),
              scaffoldBackgroundColor: appTheme.background, // Set background for dark mode
            )
          : ThemeData.light().copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: appTheme.background,
                foregroundColor: appTheme.actionGradientStart,
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


class UserInfoCollectionDialog extends ConsumerStatefulWidget {
  const UserInfoCollectionDialog({super.key});

  @override
  ConsumerState<UserInfoCollectionDialog> createState() => _UserInfoCollectionDialogState();
}

class _UserInfoCollectionDialogState extends ConsumerState<UserInfoCollectionDialog> {
  final UserInfoCollectionDB _db = UserInfoCollectionDB();
  final Map<String, dynamic> _userResponses = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _db.loadQuestions();
    _userResponses.addAll(_db.loadUserResponses());
  }

  Widget _buildQuestionWidget(Question question) {
    switch (question.type) {
      case QuestionType.text:
      case QuestionType.number:
        return TextFormField(
          initialValue: _userResponses[question.id] ?? '',
          decoration: InputDecoration(
            labelText: question.text,
            border: const OutlineInputBorder(),
          ),
          keyboardType: question.type == QuestionType.number
              ? TextInputType.number
              : TextInputType.text,
          onChanged: (value) {
            setState(() {
              _userResponses[question.id] = value;
            });
          },
        );

      case QuestionType.singleChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(question.text, style: const TextStyle(fontSize: 16)),
            ),
            ...question.options!.map(
              (option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _userResponses[question.id],
                onChanged: (value) {
                  setState(() {
                    _userResponses[question.id] = value;
                  });
                },
              ),
            ),
          ],
        );

      case QuestionType.multiChoice:
        if (_userResponses[question.id] == null) {
          _userResponses[question.id] = <String>[];
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(question.text, style: const TextStyle(fontSize: 16)),
            ),
            ...question.options!.map(
              (option) => CheckboxListTile(
                title: Text(option),
                value: (_userResponses[question.id] as List<String>).contains(option),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      (_userResponses[question.id] as List<String>).add(option);
                    } else {
                      (_userResponses[question.id] as List<String>).remove(option);
                    }
                  });
                },
              ),
            ),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  String _generateInitialPrompt() {
    final StringBuffer prompt = StringBuffer();
    prompt.writeln("Here is some initial information about me:");

    for (var question in _db.questions) {
      final answer = _userResponses[question.id];
      if (answer != null) {
        prompt.writeln("${question.text}: ${answer.toString()}");
      }
    }

    prompt.writeln(
      "\nBased on this, analyze my personality, goals, constraints, clear all existing goals, personality,additional information, add new goals, personality,additional information based on the quiz. don't ask questions. just do it"
    );

    return prompt.toString();
  }

  Future<void> _submitResponses() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save user responses
      await _db.saveUserResponses(_userResponses);
      print('User Responses: $_userResponses');

      // Generate and send initial prompt
      final String initialPrompt = _generateInitialPrompt();
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final String geminiResponse = await SupabaseGeminiService.sendChatMessage(user.id, initialPrompt);
      print('Gemini Initial Response: $geminiResponse');

      // Mark onboarding as completed
      final settingsBox = Hive.box('settings');
      await settingsBox.put('onboarding_completed', true);

      // Close the dialog
      Navigator.of(context).pop();

      // Navigate to chat screen with optimize message
      final optimizeMessage = 'Optimize my app and daily routine based on the information I just provided. Suggest improvements, new habits, and personalized recommendations.';
      Navigator.of(context).pushReplacementNamed('/chat', arguments: optimizeMessage);

    } catch (e) {
      print('Error submitting responses: $e');
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to submit responses: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    final settingsBox = Hive.box('settings');
                    await settingsBox.put('onboarding_completed', true);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Please provide some information about yourself.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._db.questions.map((question) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildQuestionWidget(question),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitResponses,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
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
