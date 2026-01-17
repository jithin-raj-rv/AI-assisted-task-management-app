import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/services/auth_service.dart';
import 'package:to_do_list/providers.dart';

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
  late final AuthService _authService;

  @override
  SettingsPageState build() {
    _authService = ref.read(authServiceProvider);
    return SettingsPageState(
      isLoading: false,
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final settingsPageViewModelProvider = NotifierProvider<SettingsPageViewModel, SettingsPageState>(() => SettingsPageViewModel());
