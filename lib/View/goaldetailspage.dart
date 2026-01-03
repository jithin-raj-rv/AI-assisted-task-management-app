import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/goaldialogbox.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/viewmodels/goals_viewmodel.dart';

class GoalDetailsPage extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalDetailsPage({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsPage> createState() => _GoalDetailsPageState();
}

class _GoalDetailsPageState extends ConsumerState<GoalDetailsPage> {
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.goal.title);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _editGoal() {
    showDialog(
      context: context,
      builder: (_) => Goaldialogbox(
        controller: _goalController,
        initialDescription: widget.goal.description,
        initialTargetDate: widget.goal.targetDate,
        onSave: (name, description, dueDate, iscompleted) {
          final updatedGoal = Goal(
            title: name,
            description: description,
            targetDate: dueDate!,
            isCompleted: widget.goal.isCompleted,
          );
          ref.read(goalsPageViewModelProvider.notifier).updateGoal(
                widget.goal.title,
                updatedGoal,
              );
          _goalController.clear();
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onCancel: () {
          _goalController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: widget.goal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editGoal,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.goal.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Completed: ${widget.goal.isCompleted ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Target Date: ${DateFormat('MMM dd, yyyy').format(widget.goal.targetDate)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Timeline Placeholder:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TODO: Implement actual timeline visualization here
            Container(
              height: 100,
              color: Colors.grey[300],
              child: const Center(
                child: Text('Timeline visualization will go here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
