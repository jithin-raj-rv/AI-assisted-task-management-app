import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/View/chatscreen.dart';
import 'package:to_do_list/View/goalspage.dart';
import 'package:to_do_list/View/settingspage.dart';
import 'package:to_do_list/View/reminderpage.dart';
import 'package:to_do_list/View/timer_prompt_page.dart';
import 'package:to_do_list/View/todopage.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/gemini_dialog.dart';
import 'package:to_do_list/util/icongradient.dart';
import 'package:to_do_list/util/tododialogbox.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/viewmodels/todo_viewmodel.dart';


class Homepage extends ConsumerStatefulWidget {
  final int initialPage;
  final String? initialPrompt;
  const Homepage({super.key, this.initialPage = 0, this.initialPrompt});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  late final PageController _pageController;
  late int _selectedIndex;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
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

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return 'My To-Do';
      case 1: return 'My Goals';
      case 2: return 'Reminders';
      case 3: return 'Timer Prompts';
      case 4: return 'Settings';
      case 5: return 'Chat';
      default: return '';
    }
  }

  List<Widget> _getActionsForIndex(int index) {
    // Actions can be added per tab if needed
    return [];
  }

void _createNewTask() {
  _textController.clear();

  showDialog(
    context: context,
    builder: (context) {
      return TodoDialogbox(
        controller: _textController,
        onSave: (name, description, dueDate, isImportant, isUrgent) async {
          await ref.read(todoViewModelProvider.notifier).createTodo(
            taskName: name,
            importance: isImportant ? "IMPORTANT" : "NOT IMPORTANT",
            urgency: isUrgent ? "URGENT" : "NOT URGENT",
            description: description,
            dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
          );
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
        onSave: (name, description, dueDate, isImportant, isUrgent) async {
          final updatedTodo = todo.copyWith(
            taskName: name,
            importance: isImportant ? "IMPORTANT" : "NOT IMPORTANT",
            urgency: isUrgent ? "URGENT" : "NOT URGENT",
            description: description,
            dueDate: dueDate ?? todo.dueDate,
            updatedAt: DateTime.now(),
          );
          await ref.read(todoViewModelProvider.notifier).updateTodo(updatedTodo);
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
        actions: _getActionsForIndex(_selectedIndex),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          TodoPage(showAppBar: true, showFAB: true),
          const GoalsPage(),
          const ReminderPage(),
          const TimerPromptPage(),
          const SettingsPage(),
          ChatScreen(initialPrompt: widget.initialPage == 5 ? widget.initialPrompt : null),
        ],
      ),
      // floatingActionButton: 
      //    Row(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       const SizedBox(width: 10),
      //       Visibility(
      //         visible: _selectedIndex != 5,
      //         child: FloatingActionButton(
      //           onPressed: () {
      //             showDialog(
      //               context: context,
      //               builder: (context) => const GeminiDialog(),
      //             );
      //           },
      //           child: const Icon(Icons.smart_toy),
      //         ),
      //       ),
      //     ],
      // ),
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
