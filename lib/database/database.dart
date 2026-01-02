import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/todo_category_model.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart'; // Import the new model
import 'package:to_do_list/models/user_feedback_model.dart'; // Import the new model
import 'package:to_do_list/models/timer_prompt_model.dart'; // Import the new model
import 'package:to_do_list/Notification/local_notification_service.dart'; // Import notification service
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class Localdata {
  List <Goal>goals =[];
  List personality =[];
  List additionalinfo =[];
  List<Todo> todolist =[]; 
  List<TodoCategory> sortlist =[]; 
  List<ScheduledNotification> scheduledNotifications = []; // New list for scheduled notifications
  List<UserFeedback> userFeedback = []; // New list for user feedback
  List<TimerPrompt> timerPrompts = []; // New list for timer prompts

  final LocalNotificationService _localNotificationService; // New field

  Localdata(this._localNotificationService); // Constructor to receive service

  ValueNotifier<int> updateNotifier = ValueNotifier(0);

  Box<dynamic> get _mybox => Hive.box('boxx');

  SupabaseClient get _supabase => Supabase.instance.client;

  List<Map<String, dynamic>> _undoStack = [];
  List<Map<String, dynamic>> _redoStack = [];

void defaultvalue (){
  todolist =[
    Todo(taskName: 'yello',isCompleted: true,importance: 'IMPORTANT',urgency: 'URGENT',description:'bla bla blaaa',dueDate: DateTime(2000, 1, 1, 10, 0)),
    Todo(taskName: 'What To Do Here',isCompleted: false,importance: 'NOT IMPORTANT',urgency: 'NOT URGENT',description:'bla bla blaaa',dueDate: DateTime(2001, 2, 15, 14, 30)),
    Todo(taskName: 'yelloo',isCompleted: true,importance: 'NOT IMPORTANT',urgency: 'URGENT',description: 'hwllo I dontu knoo',dueDate: DateTime(2020, 7, 20, 9, 0)),
    Todo(taskName: 'What Too Do Here',isCompleted: false,importance: 'IMPORTANT',urgency: 'NOT URGENT',description: 'ayyo ayyoo',dueDate: DateTime(2030, 11, 5, 18, 45))
  ]; 
  goals=[
    Goal(title: 'Learn Flutter', description: 'Complete the Flutter course on Udemy', targetDate: DateTime(2024, 12, 31), isCompleted: false),
    Goal(title: 'Build a Portfolio', description: 'Create a personal portfolio website to showcase projects', targetDate: DateTime(2024, 11, 30), isCompleted: false),
    Goal(title: 'Read More Books', description: 'Read at least 12 books this year on various topics', targetDate: DateTime(2024, 12, 31), isCompleted: false),
  ];
  scheduledNotifications = [
    ScheduledNotification(
      id: 0,
      title: 'Morning Reminder',
      body: 'Time to start your daily tasks!',
      scheduledDate: DateTime.now().add(const Duration(days: 1, hours: 8)),
      payload: 'morning_tasks',
    ),
    ScheduledNotification(
      id: 1,
      title: 'Meeting Alert',
      body: 'Team meeting in 30 minutes',
      scheduledDate: DateTime.now().add(const Duration(days: 2, hours: 14, minutes: 30)),
      payload: 'team_meeting',
    ),
  ];

  personality = [
    "Introvert",
    "Logical thinker",
    "Independent",
    "Problem solver",
    "Curious learner",
    "Calm under pressure",
    "Observant",
    "Practical mindset"
  ];
  additionalinfo = [
    "Enjoys working alone or in small teams",
    "Learns best by doing projects",
    "Prefers clear goals over vague plans",
    "Interested in technology and startups",
    "Values freedom and flexibility",
    "Focuses on efficiency and results",
    "Takes time to open up socially",
    "Motivated by skill mastery"
  ];

  for (var todo in todolist) {
    final category = TodoCategory(importance: todo.importance, urgency: todo.urgency);
    if (!sortlist.contains(category)) {
      sortlist.add(category);
    }
  }
  updatedata();
}

void loaddata (){
  final rawSortList = _mybox.get("SORTLIST") as List<dynamic>? ?? [];
  sortlist = rawSortList.map((item) => TodoCategory.fromHiveList(item as List<dynamic>)).toList();

  final rawTodoList = _mybox.get("TODOLIST") as List<dynamic>? ?? [];
  todolist = rawTodoList.map((item) => Todo.fromHiveList(item as List<dynamic>)).toList();

   final rawGoals = _mybox.get("GOALS") as List<dynamic>? ?? [];
  goals = rawGoals
      .map((item) => Goal.fromHiveList(item as List<dynamic>))
      .toList();
  final rawScheduledNotifications = _mybox.get("SCHEDULED_NOTIFICATIONS") as List<dynamic>? ?? [];
  scheduledNotifications = rawScheduledNotifications.map((item) => ScheduledNotification.fromHiveList(item as List<dynamic>)).toList();

  final rawUserFeedback = _mybox.get("USER_FEEDBACK") as List<dynamic>? ?? [];
  userFeedback = rawUserFeedback.map((item) => UserFeedback.fromHiveList(item as List<dynamic>)).toList();

  final rawTimerPrompts = _mybox.get("TIMER_PROMPTS") as List<dynamic>? ?? [];
  timerPrompts = rawTimerPrompts.map((item) => TimerPrompt.fromHiveList(item as List<dynamic>)).toList();

  personality = _mybox.get("PERSONALITY") ?? [];
  additionalinfo = _mybox.get("ADDITIONALINFO") ?? [];
}


  void updatedata ({bool isUndoRedo = false}){
    if (!isUndoRedo) {
    _redoStack.clear();
  }
  _mybox.put("SORTLIST", sortlist.map((cat) => cat.toHiveList()).toList());
  _mybox.put("TODOLIST", todolist.map((todo) => todo.toHiveList()).toList());
  _mybox.put(
  "GOALS",
  goals.map((goal) => goal.toHiveList()).toList(),
);
  _mybox.put("SCHEDULED_NOTIFICATIONS", scheduledNotifications.map((notification) => notification.toHiveList()).toList());
  _localNotificationService.rescheduleAllNotifications(scheduledNotifications); // Reschedule notifications
  _mybox.put("USER_FEEDBACK", userFeedback.map((item) => item.toHiveList()).toList());
  _mybox.put("TIMER_PROMPTS", timerPrompts.map((item) => item.toHiveList()).toList());

  _mybox.put("PERSONALITY", personality);
  _mybox.put("ADDITIONALINFO", additionalinfo);

  // add logic
  for (var todo in todolist) {
    final category = TodoCategory(importance: todo.importance, urgency: todo.urgency);
    if (!sortlist.contains(category)) {
      sortlist.add(category);
    }
  }

  // removal logic
  // Create a set of categories currently present in todolist for efficient lookup
  final currentCategories = todolist.map((todo) => TodoCategory(importance: todo.importance, urgency: todo.urgency)).toSet();

  // Remove categories from sortlist that are no longer in todolist
  sortlist.removeWhere((category) => !currentCategories.contains(category));

  updateNotifier.value++;

  // Sync to Supabase if user is logged in
  final user = _supabase.auth.currentUser;
  if (user != null) {
    _syncToSupabase();
  }
}

Future<void> _syncToSupabase() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  // Sync todos
  for (final todo in todolist) {
    await _supabase.from('todos').upsert({
      'id': todo.id,
      'user_id': user.id,
      'task_name': todo.taskName,
      'is_completed': todo.isCompleted,
      'importance': todo.importance,
      'urgency': todo.urgency,
      'description': todo.description,
      'due_date': todo.dueDate?.toIso8601String(),
    });
  }

  // Sync goals
  for (final goal in goals) {
    await _supabase.from('goals').upsert({
      'id': goal.id,
      'user_id': user.id,
      'title': goal.title,
      'description': goal.description,
      'target_date': goal.targetDate.toIso8601String(),
      'is_completed': goal.isCompleted,
    });
  }

  // Sync timer prompts
  for (final timerPrompt in timerPrompts) {
    await _supabase.from('timer_prompts').upsert({
      'id': timerPrompt.id,
      'user_id': user.id,
      'prompt': timerPrompt.prompt,
      'response': timerPrompt.response,
      'scheduled_time': timerPrompt.scheduledTime.toIso8601String(),
      'is_recurring': timerPrompt.isRecurring,
      'weekdays': timerPrompt.weekdays,
      'sent': timerPrompt.sent,
    });
  }

  // For settings
  await _supabase.from('user_settings').upsert({
    'user_id': user.id,
    'setting_key': 'personality',
    'setting_value': personality,
  });
  await _supabase.from('user_settings').upsert({
    'user_id': user.id,
    'setting_key': 'additional_info',
    'setting_value': additionalinfo,
  });
}

Future<void> syncFromSupabase() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  // Fetch from Supabase
  try {
    final todosData = await _supabase.from('todos').select('*').eq('user_id', user.id) as List;
    todolist = todosData.map((t) => Todo(
      id: t['id'],
      taskName: t['task_name'],
      isCompleted: t['is_completed'],
      importance: t['importance'],
      urgency: t['urgency'],
      description: t['description'],
      dueDate: t['due_date'] != null ? DateTime.parse(t['due_date']! as String) : DateTime.now(),
    )).toList();
  } catch (e) {
    print('Error syncing todos: $e');
  }

  try {
    final goalsData = await _supabase.from('goals').select('*').eq('user_id', user.id) as List;
    goals = goalsData.map((g) => Goal(
      id: g['id'],
      title: g['title'],
      description: g['description'],
      targetDate: DateTime.parse(g['target_date']),
      isCompleted: g['is_completed'],
    )).toList();
  } catch (e) {
    print('Error syncing goals: $e');
  }

  try {
    final timerPromptsData = await _supabase.from('timer_prompts').select('*').eq('user_id', user.id) as List;
    timerPrompts = timerPromptsData.map((tp) => TimerPrompt(
      id: tp['id'],
      prompt: tp['prompt'],
      scheduledTime: DateTime.parse(tp['scheduled_time']),
      response: tp['response'],
      isRecurring: tp['is_recurring'],
      weekdays: (tp['weekdays'] as List<dynamic>?)?.cast<int>(),
      sent: tp['sent'],
    )).toList();
  } catch (e) {
    print('Error syncing timer prompts: $e');
  }
  try {
    final settingsData = await _supabase.from('user_settings').select('*').eq('user_id', user.id) as List;
    for (final setting in settingsData) {
      if (setting['setting_key'] == 'personality') {
        personality = setting['setting_value'];
      } else if (setting['setting_key'] == 'additional_info') {
        additionalinfo = setting['setting_value'];
      }
    }
  } catch (e) {
    print('Error syncing settings: $e');
  }

  // Update Hive and notify
  updatedata();
}

void setupRealtimeSubscriptions() {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  _supabase.from('todos').stream(primaryKey: ['id']).eq('user_id', user.id).listen((data) {
    // Update local data and notify
    todolist = data.map((t) => Todo(
      id: t['id'],
      taskName: t['task_name'],
      isCompleted: t['is_completed'],
      importance: t['importance'],
      urgency: t['urgency'],
      description: t['description'],
      dueDate: t['due_date'] != null ? DateTime.parse(t['due_date']! as String) : DateTime.now(),
    )).toList();
    updatedata();
  });

  _supabase.from('goals').stream(primaryKey: ['id']).eq('user_id', user.id).listen((data) {
    goals = data.map((g) => Goal(
      id: g['id'],
      title: g['title'],
      description: g['description'],
      targetDate: DateTime.parse(g['target_date']),
      isCompleted: g['is_completed'],
    )).toList();
    updatedata();
  });

  _supabase.from('timer_prompts').stream(primaryKey: ['id']).eq('user_id', user.id).listen((data) {
    timerPrompts = data.map((tp) => TimerPrompt(
      id: tp['id'],
      prompt: tp['prompt'],
      scheduledTime: DateTime.parse(tp['scheduled_time']),
      response: tp['response'],
      isRecurring: tp['is_recurring'],
      weekdays: (tp['weekdays'] as List<dynamic>?)?.cast<int>(),
      sent: tp['sent'],
    )).toList();
    updatedata();
  });
}

Map<String, dynamic> _createSnapshot() {
    return {
      'todolist': todolist.map((e) => e.clone()).toList(),
      'goals': goals.map((e) => e.clone()).toList(),
      'scheduledNotifications': scheduledNotifications.map((e) => e.clone()).toList(),
      'timerPrompts': timerPrompts.map((e) => TimerPrompt(
        prompt: e.prompt,
        scheduledTime: e.scheduledTime,
        response: e.response,
        isRecurring: e.isRecurring,
        weekdays: e.weekdays,
        id: e.id,
        sent: e.sent,
      )).toList(),
    };
  }

  void saveStateForUndo() {
    _undoStack.add(_createSnapshot());
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_createSnapshot());
      final lastState = _undoStack.removeLast();
      _restoreState(lastState);
      updatedata(isUndoRedo: true);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_createSnapshot());
      final nextState = _redoStack.removeLast();
      _restoreState(nextState);
      updatedata(isUndoRedo: true);
    }
  }

  void _restoreState(Map<String, dynamic> state) {
    todolist = List<Todo>.from(state['todolist']);
    goals = List<Goal>.from(state['goals']);
    scheduledNotifications = List<ScheduledNotification>.from(state['scheduledNotifications']);
    timerPrompts = List<TimerPrompt>.from(state['timerPrompts']);
  }

}
