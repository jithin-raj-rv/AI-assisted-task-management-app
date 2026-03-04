import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/util/mediumgradienttext.dart';
import 'package:to_do_list/viewmodels/todo_viewmodel.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/util/todotile.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/todo_category_model.dart';
import 'package:to_do_list/util/tododialogbox.dart';
import 'package:to_do_list/util/offline_utils.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/services/connectivity_service.dart';

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

class TodoPage extends ConsumerStatefulWidget {
  final bool showAppBar;
  final bool showFAB;

  const TodoPage({
    super.key,
    this.showAppBar = true,
    this.showFAB = true,
  });

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  void _showTodoDialog({Todo? todo}) {
    _taskNameController.text = todo?.taskName ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TodoDialogbox(
          controller: _taskNameController,
          initialDescription: todo?.description,
          initialImportance: todo?.importance == 'IMPORTANT',
          initialUrgency: todo?.urgency == 'URGENT',
          initialDueDate: todo?.dueDate,
          onSave: (
            String name,
            String description,
            DateTime? dueDate,
            bool isImportant,
            bool isUrgent,
          ) async {
            final connectivity = ref.read(connectivityServiceProvider);
            if (connectivity.currentStatus != ConnectivityStatus.online) {
              OfflineUtils.showOfflinePopup(context);
              return;
            }

            final importance = isImportant ? 'IMPORTANT' : 'NOT IMPORTANT';
            final urgency = isUrgent ? 'URGENT' : 'NOT URGENT';
            if (todo != null) {
              // Update existing todo
              final updatedTodo = todo.copyWith(
                taskName: name,
                description: description,
                importance: importance,
                urgency: urgency,
                dueDate: dueDate ?? todo.dueDate,
              );
              await ref.read(todoViewModelProvider.notifier).updateTodo(updatedTodo);
            } else {
              // Add new todo
              await ref.read(todoViewModelProvider.notifier).createTodo(
                    taskName: name,
                    importance: importance,
                    urgency: urgency,
                    description: description,
                    dueDate: dueDate,
                  );
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoViewModelProvider);
    final appTheme = ref.watch(themeProvider);

    final todoList = todoState.todos;
    if (todoList.isEmpty) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: appTheme.background,
                title: Tittlegradient(text: "My To-Do"),
              )
            : null,
        body: Center(
            child: Text('No todos yet!', style: TextStyle(color: Colors.white))),
        floatingActionButton: widget.showFAB
            ? FloatingActionButton(
                onPressed: () => _showTodoDialog(),
                child: const Icon(Icons.add),
              )
            : null,
      );
    }
    final sortList = deriveCategories(todoList);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: appTheme.background,
              title: Tittlegradient(text: "My To-Do"),
            )
          : null,
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

              final List<Todo> matchingTodos = todoList.where((todo) {
                return todo.importance == sortTitle && todo.urgency == sortSub;
              }).toList();

              if (matchingTodos.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Mediumgradienttext(
                    text:"$sortTitle $sortSub",
                    fontsize:18,
                  ),
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
                        click: (value) async {
                          final connectivity = ref.read(connectivityServiceProvider);
                          if (connectivity.currentStatus != ConnectivityStatus.online) {
                            OfflineUtils.showOfflinePopup(context);
                            return;
                          }
                          await ref
                              .read(todoViewModelProvider.notifier)
                              .toggleCompletion(todo.id!);
                        },
                        onpressed: () async {
                          final connectivity = ref.read(connectivityServiceProvider);
                          if (connectivity.currentStatus != ConnectivityStatus.online) {
                            OfflineUtils.showOfflinePopup(context);
                            return;
                          }
                          await ref
                              .read(todoViewModelProvider.notifier)
                              .deleteTodo(todo.id!);
                        },
                        onEdit: () => _showTodoDialog(todo: todo),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: widget.showFAB
          ? FloatingActionButton(
              onPressed: () => _showTodoDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
