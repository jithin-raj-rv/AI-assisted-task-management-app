import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/goaldialogbox.dart';
import 'package:to_do_list/util/goaltile.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/viewmodels/goals_viewmodel.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/util/mediumgradienttext.dart';
import 'package:to_do_list/util/offline_utils.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/services/connectivity_service.dart';

class GoalCategory {
  final String importance;
  final String urgency;

  GoalCategory({
    required this.importance,
    required this.urgency,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GoalCategory &&
        other.importance == importance &&
        other.urgency == urgency;
  }

  @override
  int get hashCode => importance.hashCode ^ urgency.hashCode;
}

int getGoalCategoryScore(String importance, String urgency) {
  if (importance == 'IMPORTANT' && urgency == 'URGENT') {
    return 1;
  }
  if (importance == 'IMPORTANT' && urgency == 'NOT URGENT') {
    return 2;
  }
  if (importance == 'NOT IMPORTANT' && urgency == 'URGENT') {
    return 3;
  }
  return 4; // NOT IMPORTANT, NOT URGENT
}

List<GoalCategory> deriveGoalCategories(List<Goal> goals) {
  final categories = goals
      .map((g) => GoalCategory(importance: g.importance, urgency: g.urgency))
      .toSet()
      .toList();
  categories.sort((a, b) {
    final scoreA = getGoalCategoryScore(a.importance, a.urgency);
    final scoreB = getGoalCategoryScore(b.importance, b.urgency);
    return scoreA.compareTo(scoreB);
  });
  return categories;
}

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
    showGoalDialog(
      context: context,
      existingGoalName: goal.title,
      existingDescription: goal.description,
      existingTargetDate: goal.targetDate,
      existingImportance: goal.importance == 'IMPORTANT',
      existingUrgency: goal.urgency == 'URGENT',
      onSave: (name, description, dueDate, isCompleted, importance, urgency) async {
        final connectivity = ref.read(connectivityServiceProvider);
        if (connectivity.currentStatus != ConnectivityStatus.online) {
          OfflineUtils.showOfflinePopup(context);
          return;
        }
        ref.read(goalsPageViewModelProvider.notifier).updateGoal(
          goal.id!,
          Goal(
            title: name,
            description: description,
            targetDate: dueDate ?? goal.targetDate,
            isCompleted: goal.isCompleted,
            id: goal.id,
            userId: goal.userId,
            createdAt: goal.createdAt,
            updatedAt: goal.updatedAt,
            importance: importance,
            urgency: urgency,
          ),
        );
      },
    );
  }

  // ---------------- ADD GOAL ----------------
  void _addGoal() {
    showGoalDialog(
      context: context,
      onSave: (name, description, dueDate, isCompleted, importance, urgency) async {
        final connectivity = ref.read(connectivityServiceProvider);
        if (connectivity.currentStatus != ConnectivityStatus.online) {
          OfflineUtils.showOfflinePopup(context);
          return;
        }
        await ref.read(goalsPageViewModelProvider.notifier).addGoal(
          Goal(
            title: name,
            description: description,
            targetDate: dueDate ?? DateTime.now(),
            importance: importance,
            urgency: urgency,
          ),
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsPageViewModelProvider);
    final List<Goal> goals = state.goals;
    final appTheme = ref.watch(themeProvider);

    print('[GoalsPage] build: rebuilding with ${goals.length} goals');

    if (goals.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: appTheme.background,
          title: Tittlegradient(text: 'My Goals'),
        ),
        body: Center(
          child: Text('No goals yet!', style: TextStyle(color: Colors.white)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addGoal(),
          child: const Icon(Icons.add),
        ),
      );
    }

    final sortList = deriveGoalCategories(goals);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: 'My Goals'),
      ),
      body: Container(
        color: appTheme.background,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ListView.builder(
            itemCount: sortList.length,
            itemBuilder: (context, outerIndex) {
              final GoalCategory category = sortList[outerIndex];
              final String importance = category.importance;
              final String urgency = category.urgency;

              final List<Goal> matchingGoals = goals.where((goal) {
                return goal.importance == importance && goal.urgency == urgency;
              }).toList();

              if (matchingGoals.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Mediumgradienttext(
                    text: "$importance $urgency",
                    fontsize: 18,
                  ),
                  ListView.builder(
                    itemCount: matchingGoals.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final Goal goal = matchingGoals[index];

                      return GoalTile(
                        goal: goal,
                        onDelete: () async {
                          final connectivity = ref.read(connectivityServiceProvider);
                          if (connectivity.currentStatus != ConnectivityStatus.online) {
                            OfflineUtils.showOfflinePopup(context);
                            return;
                          }
                          await ref
                              .read(goalsPageViewModelProvider.notifier)
                              .deleteGoal(goal.id!);
                        },
                        onEdit: () => _editGoal(goal),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addGoal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
