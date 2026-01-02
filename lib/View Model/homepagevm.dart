import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/todo_category_model.dart';
import 'package:to_do_list/main.dart'; // Import the main.dart to access localNotificationService
import 'package:to_do_list/providers.dart';
import 'dart:async';

int getCategoryScore(TodoCategory category) {
  if (category.importance == 'IMPORTANT' && category.urgency == 'URGENT') {
    return 1;
  }
  if (category.importance == 'IMPORTANT' && category.urgency == 'NOT URGENT') {
    return 2;
  }
  if (category.importance == 'NOT IMPORTANT' && category.urgency == 'URGENT') {
    return 3;
  }
  return 4; // NOT IMPORTANT, NOT URGENT
}

List<TodoCategory> deriveCategories(List<Todo> todos) {
  final categories = todos
      .map((t) => TodoCategory(importance: t.importance, urgency: t.urgency))
      .toSet()
      .toList();
  categories.sort((a, b) => getCategoryScore(a).compareTo(getCategoryScore(b)));
  return categories;
}

// Define the view model
class HomePageViewModel {
  final Box<Todo> todosBox = Hive.box<Todo>('todos');
  List<Map<String, dynamic>> _undoStack = [];
  List<Map<String, dynamic>> _redoStack = [];

  void init() {
    // If no todos, add defaults
    if (todosBox.isEmpty) {
      final defaults = [
        Todo(taskName: 'yello', isCompleted: true, importance: 'IMPORTANT', urgency: 'URGENT', description: 'bla bla blaaa', dueDate: DateTime(2000, 1, 1, 10, 0)),
        Todo(taskName: 'What To Do Here', isCompleted: false, importance: 'NOT IMPORTANT', urgency: 'NOT URGENT', description: 'bla bla blaaa', dueDate: DateTime(2001, 2, 15, 14, 30)),
        Todo(taskName: 'yelloo', isCompleted: true, importance: 'NOT IMPORTANT', urgency: 'URGENT', description: 'hwllo I dontu knoo', dueDate: DateTime(2020, 7, 20, 9, 0)),
        Todo(taskName: 'What Too Do Here', isCompleted: false, importance: 'IMPORTANT', urgency: 'NOT URGENT', description: 'ayyo ayyoo', dueDate: DateTime(2030, 11, 5, 18, 45))
      ];
      for (int i = 0; i < defaults.length; i++) {
        defaults[i].id ??= i.toString();
        todosBox.put(defaults[i].id!, defaults[i]);
      }
    }
  }

  void checkboxchanged(String id) {
    saveStateForUndo();
    final todo = todosBox.get(id);
    if (todo != null) {
      todo.isCompleted = !todo.isCompleted;
      todosBox.put(id, todo);
    }
  }

  void saveIt(String taskName, String importance, String urgency, String description, DateTime dueDate) {
    if (taskName.isNotEmpty) {
      saveStateForUndo();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final todo = Todo(
        id: id,
        taskName: taskName,
        importance: importance,
        urgency: urgency,
        description: description,
        dueDate: dueDate,
      );
      todosBox.put(id, todo);

      // Trigger notification for new ToDo item
      localNotificationService.showNotification(
        id: int.parse(id), // Unique ID for each notification
        title: 'New ToDo Added!',
        body: 'You added: $taskName. Don\'t forget to complete it!',
        payload: 'new_todo_$id',
      );
    }
  }

  void updateTask(String id, String taskName, String importance, String urgency, String description, DateTime dueDate) {
    saveStateForUndo();
    final todo = todosBox.get(id);
    if (todo != null) {
      todo.taskName = taskName;
      todo.importance = importance;
      todo.urgency = urgency;
      todo.description = description;
      todo.dueDate = dueDate;
      todosBox.put(id, todo);
    }
  }

  void deleteIt(String id) {
    saveStateForUndo();
    todosBox.delete(id);
  }

  void saveStateForUndo() {
    _redoStack.clear();
    final snapshot = todosBox.values.map((e) => e.clone()).toList();
    _undoStack.add({'todos': snapshot});
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add({'todos': todosBox.values.map((e) => e.clone()).toList()});
      final lastState = _undoStack.removeLast();
      _restoreState(lastState);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add({'todos': todosBox.values.map((e) => e.clone()).toList()});
      final nextState = _redoStack.removeLast();
      _restoreState(nextState);
    }
  }

  void _restoreState(Map<String, dynamic> state) {
    todosBox.clear();
    final todos = state['todos'] as List<Todo>;
    for (final todo in todos) {
      todosBox.put(todo.id!, todo);
    }
  }
}

final homePageViewModelProvider = Provider<HomePageViewModel>((ref) {
  final vm = HomePageViewModel();
  vm.init(); // Initialize immediately when provider is created
  return vm;
});
