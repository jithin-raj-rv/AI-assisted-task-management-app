import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/providers.dart';

class GoalsPageState {
  final List<Goal> goals;
  final bool isLoading;

  const GoalsPageState({
    this.goals = const [],
    this.isLoading = false,
  });

  GoalsPageState copyWith({
    List<Goal>? goals,
    bool? isLoading,
  }) {
    return GoalsPageState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalsPageViewModel extends Notifier<GoalsPageState> {
  List<Map<String, dynamic>> _undoStack = [];
  List<Map<String, dynamic>> _redoStack = [];

  @override
  GoalsPageState build() {
    // Initialize default goals if box is empty
    final goalsBox = ref.read(goalsRepositoryProvider).box;
    if (goalsBox.isEmpty) {
      final defaultGoals = [
        Goal(title: 'Learn Flutter', description: 'Complete the Flutter course on Udemy', targetDate: DateTime(2024, 12, 31), isCompleted: false),
        Goal(title: 'Build a Portfolio', description: 'Create a personal portfolio website to showcase projects', targetDate: DateTime(2024, 11, 30), isCompleted: false),
        Goal(title: 'Read More Books', description: 'Read at least 12 books this year on various topics', targetDate: DateTime(2024, 12, 31), isCompleted: false),
      ];
      for (final goal in defaultGoals) {
        goalsBox.put(goal.title, goal);
      }
    }

    // Load goals from repository
    final goalsAsync = ref.watch(goalsProvider);
    return goalsAsync.maybeWhen(
      data: (goals) => GoalsPageState(goals: goals, isLoading: false),
      orElse: () => const GoalsPageState(isLoading: true),
    );
  }

  void _saveStateForUndo() {
    _redoStack.clear();
    final snapshot = state.goals.map((e) => e.clone()).toList();
    _undoStack.add({'goals': snapshot});
  }

  Future<void> addGoal(String title, String description, DateTime targetDate) async {
    _saveStateForUndo();
    final repo = ref.read(goalsRepositoryProvider);
    final goal = Goal(title: title, description: description, targetDate: targetDate);
    await repo.addGoal(goal);
    // State will update automatically via provider
  }

  Future<void> deleteGoal(String title) async {
    _saveStateForUndo();
    final repo = ref.read(goalsRepositoryProvider);
    await repo.deleteGoal(title);
    // State will update automatically via provider
  }

  // Backwards-compatible alias used by UI: removeGoal -> deleteGoal
  Future<void> removeGoal(String title) async {
    await deleteGoal(title);
  }

  Future<void> updateGoal(String title, String newTitle, String newDescription, DateTime newTargetDate) async {
    _saveStateForUndo();
    final repo = ref.read(goalsRepositoryProvider);
    final goal = repo.getGoal(title);
    if (goal != null) {
      final updatedGoal = Goal(
        title: newTitle,
        description: newDescription,
        targetDate: newTargetDate,
        isCompleted: goal.isCompleted,
      );
      await repo.updateGoal(newTitle, updatedGoal);
      if (newTitle != title) {
        await repo.deleteGoal(title); // Remove old key if title changed
      }
    }
  }

  Future<void> undo() async {
    if (_undoStack.isNotEmpty) {
      _redoStack.add({'goals': state.goals.map((e) => e.clone()).toList()});
      final lastState = _undoStack.removeLast();
      final goals = List<Goal>.from(lastState['goals']);
      final repo = ref.read(goalsRepositoryProvider);
      await repo.box.clear();
      for (final goal in goals) {
        await repo.addGoal(goal);
      }
    }
  }

  Future<void> redo() async {
    if (_redoStack.isNotEmpty) {
      _undoStack.add({'goals': state.goals.map((e) => e.clone()).toList()});
      final nextState = _redoStack.removeLast();
      final goals = List<Goal>.from(nextState['goals']);
      final repo = ref.read(goalsRepositoryProvider);
      await repo.box.clear();
      for (final goal in goals) {
        await repo.addGoal(goal);
      }
    }
  }
}

final goalsPageViewModelProvider =
    NotifierProvider<GoalsPageViewModel, GoalsPageState>(
  () => GoalsPageViewModel(),
);
