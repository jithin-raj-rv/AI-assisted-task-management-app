import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/models/additional_info_model.dart';
import 'package:to_do_list/services/additional_info_sync_service.dart';
import 'package:to_do_list/cache/additional_info_cache.dart';
import 'package:to_do_list/sync_providers.dart';

class AdditionalInfoPageState {
  final List<AdditionalInfo> infoItems;
  final bool isLoading;

  AdditionalInfoPageState({
    this.infoItems = const [],
    this.isLoading = false,
  });

  AdditionalInfoPageState copyWith({List<AdditionalInfo>? infoItems, bool? isLoading}) {
    return AdditionalInfoPageState(
      infoItems: infoItems ?? this.infoItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdditionalInfoPageViewModel extends Notifier<AdditionalInfoPageState> {
  final AdditionalInfoCache _cache = AdditionalInfoCache();
  late final AdditionalInfoSyncService _syncService;

  @override
  AdditionalInfoPageState build() {
    _syncService = ref.watch(additionalInfoSyncServiceProvider);
    print('[AdditionalInfoViewModel] Build called, setting up cache listener');
    _cache.watchAll().listen((infoItems) {
      print('[AdditionalInfoViewModel] ===== CACHE CHANGE DETECTED =====');
      print('[AdditionalInfoViewModel] Received ${infoItems.length} info items from cache');
      infoItems.forEach((info) => print('[AdditionalInfoViewModel] Info: ${info.info} (id: ${info.id})'));
      print('[AdditionalInfoViewModel] Updating state with new info items');
      state = state.copyWith(infoItems: infoItems, isLoading: false);
      print('[AdditionalInfoViewModel] State updated successfully');
    });
    return AdditionalInfoPageState(
      infoItems: [],
      isLoading: false,
    );
  }

  Future<void> addInfo(String infoText) async {
    print('[AdditionalInfoViewModel] ===== ADDING INFO =====');
    print('[AdditionalInfoViewModel] Info text: $infoText');
    final newInfo = AdditionalInfo(info: infoText);
    await _syncService.createInfo(newInfo);
    final updatedInfoItems = await _cache.getAll();
    state = state.copyWith(infoItems: updatedInfoItems);
    print('[AdditionalInfoViewModel] Info added successfully. Total info items: ${updatedInfoItems.length}');
  }

  Future<void> updateInfo(String id, String newInfoText) async {
    print('[AdditionalInfoViewModel] ===== UPDATING INFO =====');
    print('[AdditionalInfoViewModel] Info ID: $id');
    print('[AdditionalInfoViewModel] New info text: $newInfoText');
    final info = state.infoItems.firstWhere((i) => i.id == id);
    final updatedInfo = info.copyWith(info: newInfoText);
    await _syncService.updateInfo(id, updatedInfo);
    final updatedInfoItems = await _cache.getAll();
    state = state.copyWith(infoItems: updatedInfoItems);
    print('[AdditionalInfoViewModel] Info updated successfully. Total info items: ${updatedInfoItems.length}');
  }

  Future<void> deleteInfo(String id) async {
    print('[AdditionalInfoViewModel] ===== DELETING INFO =====');
    print('[AdditionalInfoViewModel] Info ID: $id');
    await _syncService.deleteInfo(id);
    final updatedInfoItems = await _cache.getAll();
    state = state.copyWith(infoItems: updatedInfoItems);
    print('[AdditionalInfoViewModel] Info deleted successfully. Total info items: ${updatedInfoItems.length}');
  }
}

final additionalInfoPageViewModelProvider = NotifierProvider<AdditionalInfoPageViewModel, AdditionalInfoPageState>(() => AdditionalInfoPageViewModel());
