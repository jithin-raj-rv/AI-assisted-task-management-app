// Workmanager-based Timer Prompt Sender
// This file handles background execution of timer prompts using Workmanager.
// It calls Gemini AI and sends chat messages in the background.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/AI/gemini_background.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/todo_category_model.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/models/user_feedback_model.dart';
import 'package:to_do_list/models/user_info_collection.dart';
import 'package:to_do_list/database/database.dart';
import 'package:to_do_list/Notification/local_notification_service.dart';
import 'package:intl/intl.dart';

// Initialize Workmanager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  print("callbackDispatcher function called");
  Workmanager().executeTask((task, inputData)
  async {
    try {
      print("executeTask started for task: $task, inputData: $inputData");
      print("Background task started for promptId: ${inputData?['promptId']}");
      // Initialize Hive for background access
      await Hive.initFlutter();

      // Register Hive Adapters
      Hive.registerAdapter(TodoAdapter());
      Hive.registerAdapter(GoalAdapter());
      Hive.registerAdapter(ScheduledNotificationAdapter());
      Hive.registerAdapter(TimerPromptAdapter());
      Hive.registerAdapter(UserFeedbackAdapter());
      Hive.registerAdapter(QuestionAdapter());
      Hive.registerAdapter(QuestionTypeAdapter());
      Hive.registerAdapter(TodoCategoryAdapter());
      Hive.registerAdapter(ReminderTypeAdapter());

      // Open all required boxes
      await Hive.openBox<Todo>('todos');
      await Hive.openBox<Goal>('goals');
      await Hive.openBox<TimerPrompt>('timer_prompts');
      await Hive.openBox<ScheduledNotification>('scheduled_notifications');
      await Hive.openBox<UserFeedback>('user_feedback');
      await Hive.openBox('settings');
      await Hive.openBox('boxx');
      await Hive.openBox('questionBox');
      await Hive.openBox('userResponsesBox');

      // Get the prompt ID and user ID from input data
      final promptId = inputData?['promptId'] as String?;
      final userId = inputData?['userId'] as String?;
      if (promptId == null || userId == null) {
        print("No promptId or userId provided");
        return Future.value(false);
      }

      // Initialize Supabase for background
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL', // Use the same config
        anonKey: 'YOUR_SUPABASE_ANON_KEY',
      );

      // Load database
      final localNotificationService = LocalNotificationService();
      await localNotificationService.init();
      final db = Localdata(localNotificationService);
      db.loaddata();

      // Find the prompt
      final promptIndex = db.timerPrompts.indexWhere((p) => p.id == promptId);
      if (promptIndex == -1) {
        print("Prompt not found for id: $promptId");
        return Future.value(false);
      }

      final prompt = db.timerPrompts[promptIndex];
      print("Found prompt: ${prompt.prompt}");

      // Execute the prompt via Supabase Edge Function
      print("Calling Supabase Edge Function for: ${prompt.prompt}");
      final supabase = Supabase.instance.client;
      final functionResponse = await supabase.functions.invoke('process-prompt', body: {
        'userId': userId,
        'userInput': prompt.prompt,
      });

      if (functionResponse.status != 200) {
        print("Edge function error: ${functionResponse.data}");
        return Future.value(false);
      }

      final response = functionResponse.data['response'] as String?;
      print("Received response from Edge Function: $response");

      // Update the prompt with response
      final timestamp = DateFormat('MMM dd, HH:mm').format(DateTime.now());
      final newEntry = "[$timestamp] $response";

      if (prompt.response != null && prompt.response!.isNotEmpty) {
        prompt.response = "$newEntry\n\n${prompt.response}";
      } else {
        prompt.response = newEntry;
      }

      prompt.sent = true;
      db.updatedata();
      print("Updated prompt with response");

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}



// Function to schedule a timer prompt with Workmanager
void scheduleTimerPrompt(TimerPrompt prompt, String userId) {
  final scheduledTime = prompt.scheduledTime;

  // Calculate delay for one-time prompts
  final now = DateTime.now();
  final delay = scheduledTime.difference(now);

  print("Scheduling timer prompt: ${prompt.id} at $scheduledTime, delay: $delay");

  if (delay.isNegative) {
    print("Scheduled time has already passed, not scheduling");
    return; // Already passed
  }

  Workmanager().registerOneOffTask(
    prompt.id,
    'executeTimerPrompt',
    inputData: {'promptId': prompt.id, 'userId': userId},
    initialDelay: delay,
  );
}

// Function to schedule recurring timer prompts
void scheduleRecurringTimerPrompt(TimerPrompt prompt, String userId) {
  if (!prompt.isRecurring) {
    print("Prompt is not recurring, not scheduling recurring task");
    return;
  }

  final frequency = prompt.weekdays != null && prompt.weekdays!.isNotEmpty
      ? Duration(days: 7) // Weekly
      : Duration(days: 1); // Daily

  print("Scheduling recurring timer prompt: ${prompt.id} with frequency: $frequency");

  Workmanager().registerPeriodicTask(
    prompt.id,
    'executeTimerPrompt',
    inputData: {'promptId': prompt.id, 'userId': userId},
    frequency: frequency,
  );
}

// Function to cancel a scheduled prompt
void cancelTimerPrompt(String promptId) {
  Workmanager().cancelByUniqueName(promptId);
}
