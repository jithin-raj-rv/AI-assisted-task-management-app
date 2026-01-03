import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/personality_trait_model.dart';
import 'package:to_do_list/services/personality_sync_service.dart';
import 'package:to_do_list/cache/personality_cache.dart';
import 'package:to_do_list/sync_providers.dart';

class PersonalityPageState {
  final List<PersonalityTrait> traits;
  final bool isLoading;

  PersonalityPageState({
    this.traits = const [],
    this.isLoading = false,
  });

  PersonalityPageState copyWith({List<PersonalityTrait>? traits, bool? isLoading}) {
    return PersonalityPageState(
      traits: traits ?? this.traits,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PersonalityPageViewModel extends Notifier<PersonalityPageState> {
  final PersonalityCache _cache = PersonalityCache();
  late final PersonalitySyncService _syncService;

  @override
  PersonalityPageState build() {
    _syncService = ref.watch(personalitySyncServiceProvider);
    print('[PersonalityViewModel] Build called, setting up cache listener');
    _cache.watchAll().listen((traits) {
      print('[PersonalityViewModel] ===== CACHE CHANGE DETECTED =====');
      print('[PersonalityViewModel] Received ${traits.length} traits from cache');
      traits.forEach((trait) => print('[PersonalityViewModel] Trait: ${trait.trait} (id: ${trait.id})'));
      print('[PersonalityViewModel] Updating state with new traits');
      state = state.copyWith(traits: traits, isLoading: false);
      print('[PersonalityViewModel] State updated successfully');
    });
    return PersonalityPageState(
      traits: [],
      isLoading: false,
    );
  }

  Future<void> addTrait(String traitText) async {
    print('[PersonalityViewModel] ===== ADDING TRAIT =====');
    print('[PersonalityViewModel] Trait text: $traitText');
    final newTrait = PersonalityTrait(trait: traitText);
    await _syncService.createTrait(newTrait);
    final updatedTraits = await _cache.getAll();
    state = state.copyWith(traits: updatedTraits);
    print('[PersonalityViewModel] Trait added successfully. Total traits: ${updatedTraits.length}');
  }

  Future<void> updateTrait(String id, String newTraitText) async {
    print('[PersonalityViewModel] ===== UPDATING TRAIT =====');
    print('[PersonalityViewModel] Trait ID: $id');
    print('[PersonalityViewModel] New trait text: $newTraitText');
    final trait = state.traits.firstWhere((t) => t.id == id);
    final updatedTrait = trait.copyWith(trait: newTraitText);
    await _syncService.updateTrait(id, updatedTrait);
    final updatedTraits = await _cache.getAll();
    state = state.copyWith(traits: updatedTraits);
    print('[PersonalityViewModel] Trait updated successfully. Total traits: ${updatedTraits.length}');
  }

  Future<void> deleteTrait(String id) async {
    print('[PersonalityViewModel] ===== DELETING TRAIT =====');
    print('[PersonalityViewModel] Trait ID: $id');
    await _syncService.deleteTrait(id);
    final updatedTraits = await _cache.getAll();
    state = state.copyWith(traits: updatedTraits);
    print('[PersonalityViewModel] Trait deleted successfully. Total traits: ${updatedTraits.length}');
  }
}

final personalityPageViewModelProvider = NotifierProvider<PersonalityPageViewModel, PersonalityPageState>(() => PersonalityPageViewModel());
