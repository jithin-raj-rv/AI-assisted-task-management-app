import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPageState {
  final bool isLoading;

  SettingsPageState({
    this.isLoading = false,
  });

  SettingsPageState copyWith({bool? isLoading}) {
    return SettingsPageState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsPageViewModel extends Notifier<SettingsPageState> {
  @override
  SettingsPageState build() {
    return SettingsPageState(
      isLoading: false,
    );
  }
}

final settingsPageViewModelProvider = NotifierProvider<SettingsPageViewModel, SettingsPageState>(() => SettingsPageViewModel());
