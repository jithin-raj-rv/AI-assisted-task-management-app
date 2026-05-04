import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/models/system_model.dart';
import 'package:to_do_list/cache/goal_cache.dart';
import 'package:to_do_list/cache/system_cache.dart';
import 'package:to_do_list/cache/to_achieve_cache.dart';
import 'package:to_do_list/services/goal_sync_service.dart';
import 'package:to_do_list/sync_providers.dart';
import 'package:to_do_list/services/system_sync_service.dart';
import 'package:to_do_list/models/to_achieve_model.dart';
import 'package:to_do_list/services/to_achieve_sync_service.dart';
import 'package:uuid/uuid.dart';

class GoalsPageState {
  final List<Goal> goals;
  final Map<String, List<System>> systems; // Map of goalId to systems
  final Map<String, List<ToAchieve>> toAchieves; // Map of goalId to toAchieves
  final bool isLoading;

  const GoalsPageState({
    this.goals = const [],
    this.systems = const {},
    this.toAchieves = const {},
    this.isLoading = false,
  });

  GoalsPageState copyWith({
    List<Goal>? goals,
    Map<String, List<System>>? systems,
    Map<String, List<ToAchieve>>? toAchieves,
    bool? isLoading,
  }) {
    return GoalsPageState(
      goals: goals ?? this.goals,
      systems: systems ?? this.systems,
      toAchieves: toAchieves ?? this.toAchieves,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalsPageViewModel extends Notifier<GoalsPageState> {
  final GoalCache _cache = GoalCache();
  final SystemCache _systemCache = SystemCache();
  final ToAchieveCache _toAchieveCache = ToAchieveCache();
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
      state = state.copyWith(goals: goals, isLoading: false);
    });
    
    // Listen to systems cache
    _systemCache.watchAll().listen((allSystems) {
      print('[GoalsPageViewModel] systems cache listener: received ${allSystems.length} systems');
      // Group systems by goalId
      final Map<String, List<System>> groupedSystems = {};
      for (final system in allSystems) {
        if (!groupedSystems.containsKey(system.goalId)) {
          groupedSystems[system.goalId] = [];
        }
        groupedSystems[system.goalId]!.add(system);
      }
      // Sort each goal's systems by priorityOrder
      for (final goalId in groupedSystems.keys) {
        groupedSystems[goalId]!.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
      }
      print('[GoalsPageViewModel] systems grouped by goal: ${groupedSystems.keys.length} goals');
      state = state.copyWith(systems: groupedSystems, isLoading: false);
    });

    // Listen to toAchieves cache
    _toAchieveCache.watchAll().listen((allToAchieves) {
      print('[GoalsPageViewModel] toAchieves cache listener: received ${allToAchieves.length} items');
      // Group toAchieves by goalId
      final Map<String, List<ToAchieve>> groupedToAchieves = {};
      for (final item in allToAchieves) {
        if (!groupedToAchieves.containsKey(item.goalId)) {
          groupedToAchieves[item.goalId] = [];
        }
        groupedToAchieves[item.goalId]!.add(item);
      }
      // Sort each goal's toAchieves by priorityOrder
      for (final goalId in groupedToAchieves.keys) {
        groupedToAchieves[goalId]!.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
      }
      state = state.copyWith(toAchieves: groupedToAchieves, isLoading: false);
    });
    
    return const GoalsPageState(isLoading: true);
  }

  Future<void> _loadInitialData() async {
    try {
      final goals = await _cache.getAll();
      final allSystems = await _systemCache.getAll();
      final allToAchieves = await _toAchieveCache.getAll();
      
      if (goals.isNotEmpty || allSystems.isNotEmpty || allToAchieves.isNotEmpty) {
        // Group systems by goalId
        final Map<String, List<System>> groupedSystems = {};
        for (final system in allSystems) {
          if (!groupedSystems.containsKey(system.goalId)) {
            groupedSystems[system.goalId] = [];
          }
          groupedSystems[system.goalId]!.add(system);
        }
        // Sort each goal's systems by priorityOrder
        for (final goalId in groupedSystems.keys) {
          groupedSystems[goalId]!.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
        }

        // Group toAchieves by goalId
        final Map<String, List<ToAchieve>> groupedToAchieves = {};
        for (final item in allToAchieves) {
          if (!groupedToAchieves.containsKey(item.goalId)) {
            groupedToAchieves[item.goalId] = [];
          }
          groupedToAchieves[item.goalId]!.add(item);
        }
        // Sort each goal's toAchieves by priorityOrder
        for (final goalId in groupedToAchieves.keys) {
          groupedToAchieves[goalId]!.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
        }
        
        state = GoalsPageState(
          goals: goals,
          systems: groupedSystems,
          toAchieves: groupedToAchieves,
          isLoading: false,
        );
        print('[GoalsPageViewModel] Loaded ${goals.length} goals, ${allSystems.length} systems, ${allToAchieves.length} toAchieves from cache');
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

  // System methods
  Future<void> addSystem(String goalId, String systemName) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    
    // Get current systems to determine the next priority order
    final currentSystems = state.systems[goalId] ?? [];
    final nextPriorityOrder = currentSystems.length;
    
    final system = System(
      id: newId,
      goalId: goalId,
      systemName: systemName,
      isCompleted: false,
      priorityOrder: nextPriorityOrder,
    );

    final syncService = ref.watch(systemSyncServiceProvider);
    await syncService.createSystem(system);
  }

  Future<void> updateSystem(String id, System updated) async {
    final syncService = ref.watch(systemSyncServiceProvider);
    await syncService.updateSystem(id, updated);
  }

  Future<void> deleteSystem(String id) async {
    final syncService = ref.watch(systemSyncServiceProvider);
    await syncService.deleteSystem(id);
  }

  Future<void> toggleSystemCompletion(String id, bool isCompleted) async {
    final syncService = ref.watch(systemSyncServiceProvider);
    final system = await syncService.getSystemById(id);
    if (system != null) {
      final updatedSystem = system.clone()..isCompleted = isCompleted;
      await syncService.updateSystem(id, updatedSystem);
    }
  }

  Future<void> reorderSystems(String goalId, List<System> systems) async {
    final syncService = ref.watch(systemSyncServiceProvider);
    await syncService.reorderSystems(goalId, systems);
  }

  Future<List<System>> getSystems(String goalId) async {
    final syncService = ref.watch(systemSyncServiceProvider);
    return await syncService.getSystems(goalId);
  }

  // To Achieve methods
  Future<void> addToAchieve(String goalId, String title, DateTime? targetDate) async {
    const uuid = Uuid();
    final newId = uuid.v4();
    
    // Get current toAchieves to determine the next priority order
    final currentToAchieves = state.toAchieves[goalId] ?? [];
    final nextPriorityOrder = currentToAchieves.length;
    
    final toAchieve = ToAchieve(
      id: newId,
      goalId: goalId,
      title: title,
      targetDate: targetDate,
      isCompleted: false,
      priorityOrder: nextPriorityOrder,
    );

    final syncService = ref.watch(toAchieveSyncServiceProvider);
    await syncService.createToAchieve(toAchieve);
  }

  Future<void> updateToAchieve(String id, ToAchieve updated) async {
    final syncService = ref.watch(toAchieveSyncServiceProvider);
    await syncService.updateToAchieve(id, updated);
  }

  Future<void> deleteToAchieve(String id) async {
    final syncService = ref.watch(toAchieveSyncServiceProvider);
    await syncService.deleteToAchieve(id);
  }

  Future<void> toggleToAchieveCompletion(String id, bool isCompleted, String goalId) async {
    final syncService = ref.watch(toAchieveSyncServiceProvider);
    final currentItems = state.toAchieves[goalId] ?? [];
    try {
      final item = currentItems.firstWhere((element) => element.id == id);
      final updatedItem = item.clone()..isCompleted = isCompleted;
      await syncService.updateToAchieve(id, updatedItem);
    } catch (e) {
      print('Could not find ToAchieve with id $id in state.');
    }
  }

  Future<void> reorderToAchieves(String goalId, List<ToAchieve> toAchieves) async {
    final syncService = ref.watch(toAchieveSyncServiceProvider);
    await syncService.reorderToAchieves(goalId, toAchieves);
  }
}

final goalsPageViewModelProvider =
    NotifierProvider<GoalsPageViewModel, GoalsPageState>(() => GoalsPageViewModel());

// Provider for systems
final systemsProvider = FutureProvider.autoDispose.family<List<System>, String>((ref, goalId) {
  final viewModel = ref.watch(goalsPageViewModelProvider.notifier);
  return viewModel.getSystems(goalId);
});
