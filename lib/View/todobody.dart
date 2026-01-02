import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/View%20Model/homepagevm.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/util/todotile.dart';
import 'package:to_do_list/models/todo_model.dart'; // Import Todo model
import 'package:to_do_list/models/todo_category_model.dart'; // Import TodoCategory model

class TodoBody extends ConsumerWidget {
  final Function(Todo) onEditTask;
  const TodoBody({super.key, required this.onEditTask});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosProvider);
    final homePageViewModel = ref.read(homePageViewModelProvider);
    final appTheme = ref.watch(themeProvider);

    return todosAsync.when(
      data: (todoList) {
        final sortList = deriveCategories(todoList);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appTheme.background,
            title: Tittlegradient(text: "My To-Do"),
            actions: [
              // Placeholder for the "toy icon" - using emoji_events for goals
            ],
          ),
          body: Container(
            color: appTheme.background,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ListView.builder(
                itemCount: sortList.length,
                itemBuilder: (context, outerIndex) {
                  final TodoCategory sortCategory = sortList[outerIndex];
                  final String sortTitle = sortCategory.importance;
                  final String sortSub = sortCategory.urgency;

                  // Filter todos that match this category
                  final List<Todo> matchingTodos = todoList.where((todo) {
                    return todo.importance == sortTitle && todo.urgency == sortSub;
                  }).toList();

                  // If no todos match → don't build anything
                  if (matchingTodos.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      // Title
                      Text(
                        "$sortTitle $sortSub",
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),

                      // Only matching todos
                      ListView.builder(
                        itemCount: matchingTodos.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final Todo todo = matchingTodos[index];

                          return Todotile(
                            todo: todo,
                            taskName: todo.taskName,
                            taskcompleted: todo.isCompleted,
                            click: (value) {
                              final repo = ref.read(todoRepositoryProvider);
                              final updatedTodo = todo.clone()..isCompleted = !todo.isCompleted;
                              repo.updateTodo(todo.id!, updatedTodo);
                            },
                            onpressed: () {
                              final repo = ref.read(todoRepositoryProvider);
                              repo.deleteTodo(todo.id!);
                            },
                            onEdit: () => onEditTask(todo),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
