import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/goal_step_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/goaldialogbox.dart';
import 'package:to_do_list/util/goal_step_dialog_box.dart';
import 'package:to_do_list/util/goal_step_tile.dart';
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
    showGoalDialog(
      context: context,
      existingGoalName: widget.goal.title,
      existingDescription: widget.goal.description,
      existingTargetDate: widget.goal.targetDate,
      existingImportance: widget.goal.importance == 'IMPORTANT',
      existingUrgency: widget.goal.urgency == 'URGENT',
      onSave: (name, description, dueDate, isCompleted, importance, urgency) async {
        final updatedGoal = Goal(
          title: name,
          description: description,
          targetDate: dueDate ?? widget.goal.targetDate,
          isCompleted: widget.goal.isCompleted,
          importance: importance,
          urgency: urgency,
        );
        await ref.read(goalsPageViewModelProvider.notifier).updateGoal(
              widget.goal.id!,
              updatedGoal,
            );
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final goalsViewModel = ref.watch(goalsPageViewModelProvider.notifier);
    final goalsState = ref.watch(goalsPageViewModelProvider);
    final goalSteps = goalsState.goalSteps[widget.goal.id] ?? [];

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
            // Goal details
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
            Row(
              children: [
                Text(
                  'Importance: ${widget.goal.importance}',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.goal.importance == 'VERY IMPORTANT' 
                        ? Colors.red 
                        : widget.goal.importance == 'IMPORTANT' 
                            ? Colors.orange 
                            : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Urgency: ${widget.goal.urgency}',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.goal.urgency == 'VERY URGENT' 
                        ? Colors.red 
                        : widget.goal.urgency == 'URGENT' 
                            ? Colors.orange 
                            : Colors.grey,
                  ),
                ),
              ],
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

            // Goal Steps Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Goal Steps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addGoalStep(context, goalsViewModel),
                  color: appTheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Goal Steps List
            goalSteps.isEmpty
                ? Center(
                    child: Text(
                      'No steps yet. Add your first step to get started!',
                      style: TextStyle(
                        color: appTheme.primary.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Expanded(
                    child: ReorderableListView.builder(
                      itemCount: goalSteps.length,
                      itemBuilder: (context, index) {
                        final step = goalSteps[index];
                        return GoalStepTile(
                          key: Key(step.id!),
                          step: step,
                          onEdit: () => _editGoalStep(context, step, goalsViewModel),
                          onDelete: () => _deleteGoalStep(step.id!, goalsViewModel),
                          onToggleComplete: () => _toggleGoalStepCompletion(
                            step.id!,
                            !step.isCompleted,
                            goalsViewModel,
                          ),
                          onMoveUp: index > 0
                              ? () => _moveStepUp(index, goalSteps, goalsViewModel)
                              : () {},
                          onMoveDown: index < goalSteps.length - 1
                              ? () => _moveStepDown(index, goalSteps, goalsViewModel)
                              : () {},
                          isFirst: index == 0,
                          isLast: index == goalSteps.length - 1,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = goalSteps.removeAt(oldIndex);
                        goalSteps.insert(newIndex, item);
                        _reorderSteps(goalSteps, goalsViewModel);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Goal Step methods
  Future<void> _addGoalStep(BuildContext context, GoalsPageViewModel viewModel) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => GoalStepDialogBox(
        controller: controller,
        onSave: (stepText) async {
          await viewModel.addGoalStep(widget.goal.id!, stepText);
          controller.clear();
          Navigator.pop(context);
        },
        onCancel: () {
          controller.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _editGoalStep(BuildContext context, GoalStep step, GoalsPageViewModel viewModel) async {
    final controller = TextEditingController(text: step.stepText);
    showDialog(
      context: context,
      builder: (_) => GoalStepDialogBox(
        controller: controller,
        initialStepText: step.stepText,
        onSave: (stepText) async {
          final updatedStep = step.clone()..stepText = stepText;
          await viewModel.updateGoalStep(step.id!, updatedStep);
          controller.clear();
          Navigator.pop(context);
        },
        onCancel: () {
          controller.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteGoalStep(String stepId, GoalsPageViewModel viewModel) async {
    await viewModel.deleteGoalStep(stepId);
  }

  Future<void> _toggleGoalStepCompletion(String stepId, bool isCompleted, GoalsPageViewModel viewModel) async {
    await viewModel.toggleGoalStepCompletion(stepId, isCompleted);
  }

  Future<void> _moveStepUp(int index, List<GoalStep> steps, GoalsPageViewModel viewModel) async {
    if (index > 0) {
      final temp = steps[index - 1];
      steps[index - 1] = steps[index];
      steps[index] = temp;
      _reorderSteps(steps, viewModel);
    }
  }

  Future<void> _moveStepDown(int index, List<GoalStep> steps, GoalsPageViewModel viewModel) async {
    if (index < steps.length - 1) {
      final temp = steps[index + 1];
      steps[index + 1] = steps[index];
      steps[index] = temp;
      _reorderSteps(steps, viewModel);
    }
  }

  Future<void> _reorderSteps(List<GoalStep> steps, GoalsPageViewModel viewModel) async {
    // Update sort order
    for (int i = 0; i < steps.length; i++) {
      steps[i].sortOrder = i;
    }
    await viewModel.reorderGoalSteps(widget.goal.id!, steps);
  }
}
