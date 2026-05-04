import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/goaldialogbox.dart';
import 'package:to_do_list/models/system_model.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/viewmodels/goals_viewmodel.dart';
import 'package:to_do_list/util/system_dialog_box.dart';
import 'package:to_do_list/util/system_tile.dart';
import 'package:to_do_list/models/to_achieve_model.dart';
import 'package:to_do_list/util/to_achieve_dialog_box.dart';
import 'package:to_do_list/util/to_achieve_tile.dart';

class GoalDetailsPage extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalDetailsPage({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsPage> createState() => _GoalDetailsPageState();
}

class _GoalDetailsPageState extends ConsumerState<GoalDetailsPage> {
  late TextEditingController _goalController;
  bool _toAchieveExpanded = false;
  bool _systemsExpanded = true;

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
      existingImportance: widget.goal.importance == 'IMPORTANT',
      existingUrgency: widget.goal.urgency == 'URGENT',
      onSave: (name, description, dueDate, isCompleted, importance, urgency) async {
        final updatedGoal = Goal(
          title: name,
          description: description,
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
    final systems = goalsState.systems[widget.goal.id] ?? [];
    final toAchieves = goalsState.toAchieves[widget.goal.id] ?? [];

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
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  // To Achieve Section
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'To Achieve',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addToAchieve(context, goalsViewModel),
                            color: appTheme.primary,
                          ),
                          Icon(
                            _toAchieveExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: appTheme.primary,
                          ),
                        ],
                      ),
                      initiallyExpanded: _toAchieveExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _toAchieveExpanded = expanded;
                        });
                      },
                      children: [
                        if (toAchieves.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No steps yet. Add your first step!',
                                style: TextStyle(
                                  color: appTheme.primary.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: toAchieves.length,
                            itemBuilder: (context, index) {
                              final toAchieve = toAchieves[index];
                              return ToAchieveTile(
                                key: Key(toAchieve.id!),
                                toAchieve: toAchieve,
                                onEdit: () => _editToAchieve(context, toAchieve, goalsViewModel),
                                onDelete: () => _deleteToAchieve(toAchieve.id!, goalsViewModel),
                                onToggleComplete: () => _toggleToAchieveCompletion(
                                  toAchieve.id!,
                                  !toAchieve.isCompleted,
                                  goalsViewModel,
                                ),
                                onMoveUp: index > 0
                                    ? () => _moveToAchieveUp(index, toAchieves, goalsViewModel)
                                    : () {},
                                onMoveDown: index < toAchieves.length - 1
                                    ? () => _moveToAchieveDown(index, toAchieves, goalsViewModel)
                                    : () {},
                                isFirst: index == 0,
                                isLast: index == toAchieves.length - 1,
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = toAchieves.removeAt(oldIndex);
                              toAchieves.insert(newIndex, item);
                              _reorderToAchieves(toAchieves, goalsViewModel);
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Systems Section
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'Systems',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addSystem(context, goalsViewModel),
                            color: appTheme.primary,
                          ),
                          Icon(
                            _systemsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: appTheme.primary,
                          ),
                        ],
                      ),
                      initiallyExpanded: _systemsExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _systemsExpanded = expanded;
                        });
                      },
                      children: [
                        if (systems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No systems yet. Add your first system!',
                                style: TextStyle(
                                  color: appTheme.primary.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: systems.length,
                            itemBuilder: (context, index) {
                              final system = systems[index];
                              return SystemTile(
                                key: Key(system.id!),
                                system: system,
                                onEdit: () => _editSystem(context, system, goalsViewModel),
                                onDelete: () => _deleteSystem(system.id!, goalsViewModel),
                                onToggleComplete: () => _toggleSystemCompletion(
                                  system.id!,
                                  !system.isCompleted,
                                  goalsViewModel,
                                ),
                                onMoveUp: index > 0
                                    ? () => _moveSystemUp(index, systems, goalsViewModel)
                                    : () {},
                                onMoveDown: index < systems.length - 1
                                    ? () => _moveSystemDown(index, systems, goalsViewModel)
                                    : () {},
                                isFirst: index == 0,
                                isLast: index == systems.length - 1,
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = systems.removeAt(oldIndex);
                              systems.insert(newIndex, item);
                              _reorderSystems(systems, goalsViewModel);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // System methods
  Future<void> _addSystem(BuildContext context, GoalsPageViewModel viewModel) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => SystemDialogBox(
        controller: controller,
        onSave: (systemName) async {
          await viewModel.addSystem(widget.goal.id!, systemName);
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

  Future<void> _editSystem(BuildContext context, System system, GoalsPageViewModel viewModel) async {
    final controller = TextEditingController(text: system.systemName);
    showDialog(
      context: context,
      builder: (_) => SystemDialogBox(
        controller: controller,
        initialStepText: system.systemName,
        onSave: (systemName) async {
          final updatedSystem = system.clone()..systemName = systemName;
          await viewModel.updateSystem(system.id!, updatedSystem);
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

  Future<void> _deleteSystem(String systemId, GoalsPageViewModel viewModel) async {
    await viewModel.deleteSystem(systemId);
  }

  Future<void> _toggleSystemCompletion(String systemId, bool isCompleted, GoalsPageViewModel viewModel) async {
    await viewModel.toggleSystemCompletion(systemId, isCompleted);
  }

  Future<void> _moveSystemUp(int index, List<System> systems, GoalsPageViewModel viewModel) async {
    if (index > 0) {
      final temp = systems[index - 1];
      systems[index - 1] = systems[index];
      systems[index] = temp;
      _reorderSystems(systems, viewModel);
    }
  }

  Future<void> _moveSystemDown(int index, List<System> systems, GoalsPageViewModel viewModel) async {
    if (index < systems.length - 1) {
      final temp = systems[index + 1];
      systems[index + 1] = systems[index];
      systems[index] = temp;
      _reorderSystems(systems, viewModel);
    }
  }

  Future<void> _reorderSystems(List<System> systems, GoalsPageViewModel viewModel) async {
    // Update priority order
    for (int i = 0; i < systems.length; i++) {
      systems[i].priorityOrder = i;
    }
    await viewModel.reorderSystems(widget.goal.id!, systems);
  }

  // To Achieve methods
  Future<void> _addToAchieve(BuildContext context, GoalsPageViewModel viewModel) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => ToAchieveDialogBox(
        controller: controller,
        onSave: (title, targetDate) async {
          await viewModel.addToAchieve(widget.goal.id!, title, targetDate);
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

  Future<void> _editToAchieve(BuildContext context, ToAchieve toAchieve, GoalsPageViewModel viewModel) async {
    final controller = TextEditingController(text: toAchieve.title);
    showDialog(
      context: context,
      builder: (_) => ToAchieveDialogBox(
        controller: controller,
        initialTitle: toAchieve.title,
        initialTargetDate: toAchieve.targetDate,
        onSave: (title, targetDate) async {
          final updated = toAchieve.clone()
            ..title = title
            ..targetDate = targetDate;
          await viewModel.updateToAchieve(toAchieve.id!, updated);
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

  Future<void> _deleteToAchieve(String id, GoalsPageViewModel viewModel) async {
    await viewModel.deleteToAchieve(id);
  }

  Future<void> _toggleToAchieveCompletion(String id, bool isCompleted, GoalsPageViewModel viewModel) async {
    await viewModel.toggleToAchieveCompletion(id, isCompleted, widget.goal.id!);
  }

  Future<void> _moveToAchieveUp(int index, List<ToAchieve> toAchieves, GoalsPageViewModel viewModel) async {
    if (index > 0) {
      final temp = toAchieves[index - 1];
      toAchieves[index - 1] = toAchieves[index];
      toAchieves[index] = temp;
      _reorderToAchieves(toAchieves, viewModel);
    }
  }

  Future<void> _moveToAchieveDown(int index, List<ToAchieve> toAchieves, GoalsPageViewModel viewModel) async {
    if (index < toAchieves.length - 1) {
      final temp = toAchieves[index + 1];
      toAchieves[index + 1] = toAchieves[index];
      toAchieves[index] = temp;
      _reorderToAchieves(toAchieves, viewModel);
    }
  }

  Future<void> _reorderToAchieves(List<ToAchieve> toAchieves, GoalsPageViewModel viewModel) async {
    for (int i = 0; i < toAchieves.length; i++) {
      toAchieves[i].priorityOrder = i;
    }
    await viewModel.reorderToAchieves(widget.goal.id!, toAchieves);
  }
}
