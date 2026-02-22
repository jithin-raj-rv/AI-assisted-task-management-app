import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/goal_step_model.dart';
import 'package:to_do_list/cache/goal_cache.dart';
import 'package:to_do_list/cache/goal_step_cache.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/services/goal_sync_service.dart';
import 'package:to_do_list/services/goal_step_sync_service.dart';
import 'package:uuid/uuid.dart';

class GoalsPageState {
  final List<Goal> goals;
  final Map<String, List<GoalStep>> goalSteps; // Map of goalId to steps
  final bool isLoading;

  const GoalsPageState({this.goals = const [], this.goalSteps = const {}, this.isLoading = false});

  GoalsPageState copyWith({List<Goal>? goals, Map<String, List<GoalStep>>? goalSteps, bool? isLoading}) {
    return GoalsPageState(
      goals: goals ?? this.goals,
      goalSteps: goalSteps ?? this.goalSteps,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalsPageViewModel extends Notifier<GoalsPageState> {
  final GoalCache _cache = GoalCache();
  final GoalStepCache _goalStepCache = GoalStepCache();
  late final GoalSyncService _syncService;

  @override
  GoalsPageState build() {
    print('[GoalsPageViewModel] build: setting up cache listener');
    _syncService = ref.watch(goalSyncServiceProvider);
    
    // Load initial data from cache immediately
    _loadInitialData();
    
    // Listen to goals cache
    _cache.watchAll().listen((goals) {
      print('[GoalsPageViewModel] cache listener: received ${goals.length} goals, updating state');
      state = GoalsPageState(goals: goals, goalSteps: state.goalSteps, isLoading: false);
    });
    
    // Listen to goal steps cache
    _goalStepCache.watchAll().listen((allSteps) {
      print('[GoalsPageViewModel] goal steps cache listener: received ${allSteps.length} steps');
      // Group steps by goalId
      final Map<String, List<GoalStep>> groupedSteps = {};
      for (final step in allSteps) {
        if (!groupedSteps.containsKey(step.goalId)) {
          groupedSteps[step.goalId] = [];
        }
        groupedSteps[step.goalId]!.add(step);
      }
      // Sort each goal's steps by sortOrder
      for (final goalId in groupedSteps.keys) {
        groupedSteps[goalId]!.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
      print('[GoalsPageViewModel] goal steps grouped by goal: ${groupedSteps.keys.length} goals');
      state = GoalsPageState(goals: state.goals, goalSteps: groupedSteps, isLoading: false);
    });
    
    return const GoalsPageState(isLoading: true);
  }

  Future<void> _loadInitialData() async {
    try {
      final goals = await _cache.getAll();
      final allSteps = await _goalStepCache.getAll();
      
      if (goals.isNotEmpty || allSteps.isNotEmpty) {
        // Group steps by goalId
        final Map<String, List<GoalStep>> groupedSteps = {};
        for (final step in allSteps) {
          if (!groupedSteps.containsKey(step.goalId)) {
            groupedSteps[step.goalId] = [];
          }
          groupedSteps[step.goalId]!.add(step);
        }
        // Sort each goal's steps by sortOrder
        for (final goalId in groupedSteps.keys) {
          groupedSteps[goalId]!.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }
        
        state = GoalsPageState(goals: goals, goalSteps: groupedSteps, isLoading: false);
        print('[GoalsPageViewModel] Loaded ${goals.length} initial goals and ${allSteps.length} goal steps from cache');
      }
    } catch (e) {
      print('[GoalsPageViewModel] Error loading initial data: $e');
    }
  }

  Future<void> addGoal(Goal goal) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    final goalWithId = Goal(
      id: newId,
      title: goal.title,
      description: goal.description,
      targetDate: goal.targetDate,
      isCompleted: goal.isCompleted,
      importance: goal.importance,
      urgency: goal.urgency,
    );

    await _syncService.createGoal(goalWithId);
  }

  Future<void> deleteGoal(String id) async {
    await _syncService.deleteGoal(id);
  }

  Future<void> updateGoal(String id, Goal updated) async {
    await _syncService.updateGoal(id, updated);
  }

  // Goal Step methods
  Future<void> addGoalStep(String goalId, String stepText) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    
    // Get current steps to determine the next sort order
    final currentSteps = state.goalSteps[goalId] ?? [];
    final nextSortOrder = currentSteps.length;
    
    final step = GoalStep(
      id: newId,
      goalId: goalId,
      stepText: stepText,
      isCompleted: false,
      sortOrder: nextSortOrder,
    );

    final syncService = ref.watch(goalStepSyncServiceProvider);
    await syncService.createGoalStep(step);
  }

  Future<void> updateGoalStep(String id, GoalStep updated) async {
    final syncService = ref.watch(goalStepSyncServiceProvider);
    await syncService.updateGoalStep(id, updated);
  }

  Future<void> deleteGoalStep(String id) async {
    final syncService = ref.watch(goalStepSyncServiceProvider);
    await syncService.deleteGoalStep(id);
  }

  Future<void> toggleGoalStepCompletion(String id, bool isCompleted) async {
    final syncService = ref.watch(goalStepSyncServiceProvider);
    final step = await syncService.getGoalStepById(id);
    if (step != null) {
      final updatedStep = step.clone()..isCompleted = isCompleted;
      await syncService.updateGoalStep(id, updatedStep);
    }
  }

  Future<void> reorderGoalSteps(String goalId, List<GoalStep> steps) async {
    final syncService = ref.watch(goalStepSyncServiceProvider);
    await syncService.reorderGoalSteps(goalId, steps);
  }

  Future<List<GoalStep>> getGoalSteps(String goalId) async {
    final syncService = ref.watch(goalStepSyncServiceProvider);
    return await syncService.getGoalSteps(goalId);
  }
}

final goalsPageViewModelProvider =
    NotifierProvider<GoalsPageViewModel, GoalsPageState>(() => GoalsPageViewModel());

// Provider for goal steps
final goalStepsProvider = FutureProvider.autoDispose.family<List<GoalStep>, String>((ref, goalId) {
  final viewModel = ref.watch(goalsPageViewModelProvider.notifier);
  return viewModel.getGoalSteps(goalId);
});
