import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/cache/todo_cache.dart';
import 'package:to_do_list/services/todo_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_list/sync_providers.dart';

class TodoState {
  final List<Todo> todos;

  const TodoState({this.todos = const []});

  TodoState copyWith({List<Todo>? todos}) {
    return TodoState(todos: todos ?? this.todos);
  }
}

class TodoViewModel extends Notifier<TodoState> {
  final TodoCache _cache = TodoCache();
  late final TodoSyncService _syncService;

  @override
  TodoState build() {
    _syncService = ref.watch(todoSyncServiceProvider);
    _cache.watchAll().listen((todos) {
      print('[TodoViewModel] Cache updated with ${todos.length} todos: ${todos.map((t) => t.id).toList()}');
      state = TodoState(todos: todos);
    });
    print('[TodoViewModel] Built TodoViewModel');
    return TodoState(todos: []);
  }



  Future<void> createTodo({
    required String taskName,
    required String importance,
    required String urgency,
    String? description,
    DateTime? dueDate,
  }) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    final todo = Todo(
      id: newId,
      taskName: taskName,
      importance: importance,
      urgency: urgency,
      description: description ?? '',
      dueDate: dueDate ?? DateTime.now(),
      isCompleted: false,
    );

    await _syncService.createTodo(todo);
  }

  Future<void> updateTodo(Todo todo) async {
    await _syncService.updateTodo(todo.id!, todo);
  }

  Future<void> deleteTodo(String id) async {
    await _syncService.deleteTodo(id);
  }

  Future<void> toggleCompletion(String id) async {
    final todos = await _cache.getAll();
    final todo = todos.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await updateTodo(updated);
  }
}

final todoViewModelProvider =
    NotifierProvider<TodoViewModel, TodoState>(() => TodoViewModel());
