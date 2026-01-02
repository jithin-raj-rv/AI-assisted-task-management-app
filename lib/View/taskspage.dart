import 'package:flutter/material.dart';
import 'package:to_do_list/View/reminderpage.dart';
import 'package:to_do_list/View/todobody.dart';
import 'package:to_do_list/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/todo_model.dart';

class TasksPage extends ConsumerStatefulWidget {
  final Function(Todo) onEditTask;
  const TasksPage({super.key, required this.onEditTask});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'To-Do'),
            Tab(text: 'Reminders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodoBody(onEditTask: widget.onEditTask),
          const ReminderPage(),
        ],
      ),
    );
  }
}
