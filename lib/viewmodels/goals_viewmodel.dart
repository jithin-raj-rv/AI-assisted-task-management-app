import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/cache/goal_cache.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/services/goal_sync_service.dart';
import 'package:uuid/uuid.dart';

class GoalsPageState {
  final List<Goal> goals;
  final bool isLoading;

  const GoalsPageState({this.goals = const [], this.isLoading = false});

  GoalsPageState copyWith({List<Goal>? goals, bool? isLoading}) {
    return GoalsPageState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalsPageViewModel extends Notifier<GoalsPageState> {
  final GoalCache _cache = GoalCache();
  late final GoalSyncService _syncService;

  @override
  GoalsPageState build() {
    print('[GoalsPageViewModel] build: setting up cache listener');
    _syncService = ref.watch(goalSyncServiceProvider);
    _cache.watchAll().listen((goals) {
      print('[GoalsPageViewModel] cache listener: received ${goals.length} goals, updating state');
      state = GoalsPageState(goals: goals, isLoading: false);
    });
    return const GoalsPageState(isLoading: true);
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
    );

    await _syncService.createGoal(goalWithId);
  }

  Future<void> deleteGoal(String id) async {
    await _syncService.deleteGoal(id);
  }

  Future<void> updateGoal(String id, Goal updated) async {
    await _syncService.updateGoal(id, updated);
  }
}

final goalsPageViewModelProvider =
    NotifierProvider<GoalsPageViewModel, GoalsPageState>(() => GoalsPageViewModel());
