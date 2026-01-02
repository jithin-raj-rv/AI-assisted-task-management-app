import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/goaldialogbox.dart';
import 'package:to_do_list/util/goaltile.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/View Model/goalspagevm.dart';
import 'package:to_do_list/util/tittlegradient.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {

  final TextEditingController _goalController = TextEditingController();


  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  // ---------------- EDIT GOAL ----------------
  void _editGoal(Goal goal) {
    _goalController.text = goal.title;

    showDialog(
      context: context,
      builder: (_) => Goaldialogbox(
        controller: _goalController,
        initialDescription: goal.description,
        initialTargetDate: goal.targetDate,
        onSave: (name, description, dueDate, isCompleted) {
          ref.read(goalsPageViewModelProvider.notifier).updateGoal(
            goal.title,
            name,
            description,
            dueDate ?? goal.targetDate,
          );
          _goalController.clear();
          Navigator.pop(context);
        },
        onCancel: () {
          _goalController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ---------------- ADD GOAL ----------------
  void _addGoal() {
    showDialog(
      context: context,
      builder: (_) => Goaldialogbox(
        controller: _goalController,
        onSave: (name, description, dueDate, isCompleted) {
          ref.read(goalsPageViewModelProvider.notifier).addGoal(
                name,
                description,
                dueDate ?? DateTime.now(),
              );
          _goalController.clear();
          Navigator.pop(context);
        },
        onCancel: () {
          _goalController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsPageViewModelProvider);
    final List<Goal> goals = state.goals;
    final appTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: 'My Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              ref.read(goalsPageViewModelProvider.notifier).undo();
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () {
              ref.read(goalsPageViewModelProvider.notifier).redo();
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGoal,
          ),
        ],
      ),
      body: goals.isEmpty
          ? const Center(child: Text("No goals yet"))
          : ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return GoalTile(
                  goal: goals[index],
                  onDelete: () {
                    ref
                        .read(goalsPageViewModelProvider.notifier)
                        .removeGoal(goals[index].title);
                  },
                  onEdit: () => _editGoal(goals[index]),
                );
              },
            ),
    );
  }
}
