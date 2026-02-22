import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/cache/todo_cache.dart';
import 'package:to_do_list/services/todo_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_list/sync_providers.dart';

class TodoState {
  final List<Todo> todos;
  final bool isLoading;

  const TodoState({this.todos = const [], this.isLoading = false});

  TodoState copyWith({List<Todo>? todos, bool? isLoading}) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TodoViewModel extends Notifier<TodoState> {
  final TodoCache _cache = TodoCache();
  late final TodoSyncService _syncService;

  @override
  TodoState build() {
    _syncService = ref.watch(todoSyncServiceProvider);
    
    // Load initial data from cache immediately
    _loadInitialData();
    
    // Then watch for changes
    _cache.watchAll().listen((todos) {
      print('[TodoViewModel] Cache updated with ${todos.length} todos: ${todos.map((t) => t.id).toList()}');
      state = TodoState(todos: todos, isLoading: false);
    });
    print('[TodoViewModel] Built TodoViewModel');
    return const TodoState(isLoading: true);
  }

  Future<void> _loadInitialData() async {
    try {
      final todos = await _cache.getAll();
      if (todos.isNotEmpty) {
        state = TodoState(todos: todos, isLoading: false);
        print('[TodoViewModel] Loaded ${todos.length} initial todos from cache');
      }
    } catch (e) {
      print('[TodoViewModel] Error loading initial data: $e');
    }
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
