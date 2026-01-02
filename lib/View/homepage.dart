import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/View%20Model/homepagevm.dart';
import 'package:to_do_list/View/chatscreen.dart';
import 'package:to_do_list/View/goalspage.dart';
import 'package:to_do_list/View/settingspage.dart';
import 'package:to_do_list/View/reminderpage.dart';
import 'package:to_do_list/View/timer_prompt_page.dart';
import 'package:to_do_list/View/todobody.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/gemini_dialog.dart';
import 'package:to_do_list/util/icongradient.dart';
import 'package:to_do_list/util/tododialogbox.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/providers.dart';


class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Init is now called when the provider is created
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

void _createNewTask() {
  _textController.clear();

  showDialog(
    context: context,
    builder: (context) {
      return TodoDialogbox(
        controller: _textController,
        onSave: (name, description, dueDate, isImportant, isUrgent) {
          final repo = ref.read(todoRepositoryProvider);
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          final todo = Todo(
            id: id,
            taskName: name,
            importance: isImportant ? "IMPORTANT" : "NOT IMPORTANT",
            urgency: isUrgent ? "URGENT" : "NOT URGENT",
            description: description,
            dueDate: dueDate!,
          );
          repo.addTodo(todo);
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      );
    },
  );
}


void _editTask(Todo todo) {
  _textController.text = todo.taskName;
  final isImportant = todo.importance == "IMPORTANT";
  final isUrgent = todo.urgency == "URGENT";

  showDialog(
    context: context,
    builder: (context) {
      return TodoDialogbox(
        controller: _textController,
        initialImportance: isImportant,
        initialUrgency: isUrgent,
        initialDescription: todo.description, // Pass existing description
        initialDueDate: todo.dueDate,       // Pass existing due date
        onSave: (name, description, dueDate, isImportant, isUrgent) {
          final repo = ref.read(todoRepositoryProvider);
          final updatedTodo = todo.clone()
            ..taskName = name
            ..importance = isImportant ? "IMPORTANT" : "NOT IMPORTANT"
            ..urgency = isUrgent ? "URGENT" : "NOT URGENT"
            ..description = description
            ..dueDate = dueDate!;
          repo.updateTodo(todo.id!, updatedTodo);
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      );
    },
  );
}

  
  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        elevation: 0,
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                ref.read(homePageViewModelProvider).undo();
              },
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: () {
                ref.read(homePageViewModelProvider).redo();
              },
            ),
          ],
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          TodoBody(onEditTask: _editTask),
          const GoalsPage(),
          const ReminderPage(),
          const TimerPromptPage(),
          const SettingsPage(),
          const ChatScreen(),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 10),
          Visibility(
            visible: _selectedIndex != 5,
            child: FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const GeminiDialog(),
                );
              },
              child: const Icon(Icons.smart_toy),
            ),
          ),
          const SizedBox(width: 10),
          Visibility(
            visible: _selectedIndex == 0,
            child: FloatingActionButton(
              onPressed: _createNewTask,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback: true,
        showUnselectedLabels: true,
        backgroundColor: appTheme.background,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icongradient(icon: Icons.list),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icongradient(icon: Icons.flag),
            label: 'Goals',
          ),
          const BottomNavigationBarItem(
            icon: Icongradient(icon: Icons.alarm),
            label: 'Reminders',
          ),
          const BottomNavigationBarItem(
            icon: Icongradient(icon: Icons.timer),
            label: 'Timer',
          ),
          const BottomNavigationBarItem(
            icon: Icongradient(icon:  Icons.settings),
            label: 'Settings',
          ),
          const BottomNavigationBarItem(
            icon: Icongradient(icon: Icons.chat),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: appTheme.primary,
        unselectedItemColor: appTheme.primaryGradient1.withAlpha(150),
      ),
    );
  }
}
