import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/services/connectivity_service.dart';
import 'package:to_do_list/cache/todo_cache.dart';

class TodoSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectivityService _connectivityService;
  final TodoCache _cache = TodoCache();

  List<dynamic> _activeChannels = [];

  TodoSyncService(this._connectivityService);

  /// Clear realtime subscriptions
  Future<void> clearRealtimeSubscriptions() async {
    final channels = List.from(_activeChannels);
    for (final ch in channels) {
      try {
        await ch.unsubscribe();
      } catch (e) {
        print('[TodoSync] Error unsubscribing: $e');
      }
    }
    _activeChannels.clear();
  }

  /// Fetch initial data from Supabase and store in cache
  Future<void> syncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    print('[TodoSync] Starting syncFromSupabase, user: ${user?.id}');
    if (user == null) {
      print('[TodoSync] User is null, skipping sync');
      return;
    }

    try {
      print('[TodoSync] Fetching todos from Supabase for user: ${user.id}');
      final todosData = await _supabase.from('todos').select('*').eq('user_id', user.id) as List;
      print('[TodoSync] Fetched ${todosData.length} raw todos from Supabase');
      final todos = todosData.map((t) {
        print('[TodoSync] Processing todo: ${t['id']} - ${t['task_name']}');
        return Todo(
          id: t['id'],
          taskName: t['task_name'],
          isCompleted: t['is_completed'] ?? false,
          importance: t['importance'],
          urgency: t['urgency'],
          description: t['description'],
          dueDate: t['due_date'] != null ? DateTime.parse(t['due_date']) : null,
        );
      }).toList();
      print('[TodoSync] Created ${todos.length} Todo objects');

      final box = await Hive.openBox<Todo>('todos');
      print('[TodoSync] Opened todos box, current length: ${box.length}');
      final newTodos = {for (var todo in todos) todo.id!: todo};
      final oldKeys = box.keys.toSet();
      final keysToDelete = oldKeys.difference(newTodos.keys.toSet());
      if (keysToDelete.isNotEmpty) {
        print('[TodoSync] Deleting ${keysToDelete.length} old todos');
        box.deleteAll(keysToDelete);
      }
      if (newTodos.isNotEmpty) {
        print('[TodoSync] Putting ${newTodos.length} new todos to cache');
        box.putAll(newTodos);
        print('[TodoSync] Cache updated, new length: ${box.length}');
      } else {
        print('[TodoSync] No new todos to put');
      }
      print('[TodoSync] Sync completed successfully');
    } catch (e) {
      print('[TodoSync] Error syncing todos: $e');
    }
  }

  /// Setup realtime subscriptions
  void setupRealtimeSubscriptions() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    clearRealtimeSubscriptions();

    final todosChannel = _supabase.channel('todos_realtime');
    _activeChannels.add(todosChannel);
    print('[TodoSync] Setting up real-time subscription for user: ${user.id}');
    todosChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'todos',
      callback: (payload) {
        print('[TodoSync] Real-time event received: ${payload.eventType} for table: ${payload.table}');
        final record = payload.newRecord ?? payload.oldRecord;
        // For DELETE events, trust RLS - if we received it, it's for our user
        if (payload.eventType.name != 'delete' && record != null && record['user_id'] != user.id) return;
        print('[TodoSync] Payload record: ${payload.newRecord ?? payload.oldRecord}');
        try {
          final box = Hive.box<Todo>('todos');
          if (payload.eventType.name == 'insert' || payload.eventType.name == 'update') {
            final record = payload.newRecord!;
            print('[TodoSync] Processing ${payload.eventType} for todo id: ${record['id']}');
            print('[TodoSync] Record fields: id=${record['id']}, task_name=${record['task_name']}, is_completed=${record['is_completed']}, importance=${record['importance']}, urgency=${record['urgency']}, description=${record['description']}, due_date=${record['due_date']}, user_id=${record['user_id']}');
            final todo = Todo(
              id: record['id'],
              taskName: record['task_name'],
              isCompleted: record['is_completed'] ?? false,
              importance: record['importance'],
              urgency: record['urgency'],
              description: record['description'],
              dueDate: record['due_date'] != null ? DateTime.parse(record['due_date']) : null,
            );
            print('[TodoSync] Created todo object: $todo');
            box.put(todo.id!, todo);
            print('[TodoSync] Updated cache for todo: ${todo.id}');
            print('[TodoSync] Cache now has ${box.length} items');
          } else if (payload.eventType.name == 'delete') {
            final record = payload.oldRecord!;
            print('[TodoSync] Processing DELETE for todo id: ${record['id']}');
            box.delete(record['id']);
            print('[TodoSync] Deleted from cache: ${record['id']}');
          }
        } catch (e, stack) {
          print('[TodoSync] Error processing realtime: $e');
          print('[TodoSync] Stack trace: $stack');
        }
      },
    );
    todosChannel.subscribe();
    print('[TodoSync] Real-time subscription subscribed');
  }

  /// Create todo
  Future<void> createTodo(Todo todo) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final supabaseData = {
      'id': todo.id,
      'user_id': currentUser.id,
      'task_name': todo.taskName,
      'is_completed': todo.isCompleted,
      'importance': todo.importance,
      'urgency': todo.urgency,
      'description': todo.description,
      'due_date': todo.dueDate?.toUtc().toIso8601String(),
    };

    await _supabase.from('todos').insert(supabaseData);
  }

  /// Update todo
  Future<void> updateTodo(String id, Todo todo) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    final supabaseData = {
      'task_name': todo.taskName,
      'is_completed': todo.isCompleted,
      'importance': todo.importance,
      'urgency': todo.urgency,
      'description': todo.description,
      'due_date': todo.dueDate?.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('todos').update(supabaseData).eq('id', id);
  }

  /// Delete todo
  Future<void> deleteTodo(String id) async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      throw Exception('Cannot sync while offline');
    }

    // Delete from Supabase
    await _supabase.from('todos').delete().eq('id', id);

    // Immediately update local cache
    final box = await Hive.openBox<Todo>('todos');
    await box.delete(id);
    print('[TodoSync] Deleted todo $id from local cache');
  }
}
