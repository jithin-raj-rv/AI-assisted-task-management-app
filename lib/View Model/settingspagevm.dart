import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPageState {
  final List personality;
  final List additionalinfo;
  final bool isLoading;

  SettingsPageState({
    this.personality = const [],
    this.additionalinfo = const [],
    this.isLoading = false,
  });

  SettingsPageState copyWith({
    List? personality,
    List? additionalinfo,
    bool? isLoading,
  }) {
    return SettingsPageState(
      personality: personality ?? this.personality,
      additionalinfo: additionalinfo ?? this.additionalinfo,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsPageViewModel extends Notifier<SettingsPageState> {
  late final Box _settingsBox;

  @override
  SettingsPageState build() {
    _settingsBox = Hive.box('settings');

    // Load defaults if empty
    if (_settingsBox.get('personality') == null) {
      _settingsBox.put('personality', [
        "Introvert",
        "Logical thinker",
        "Independent",
        "Problem solver",
        "Curious learner",
        "Calm under pressure",
        "Observant",
        "Practical mindset"
      ]);
    }
    if (_settingsBox.get('additional_info') == null) {
      _settingsBox.put('additional_info', [
        "Enjoys working alone or in small teams",
        "Learns best by doing projects",
        "Prefers clear goals over vague plans",
        "Interested in technology and startups",
        "Values freedom and flexibility",
        "Focuses on efficiency and results",
        "Takes time to open up socially",
        "Motivated by skill mastery"
      ]);
    }

    return SettingsPageState(
      personality: _settingsBox.get('personality', defaultValue: []),
      additionalinfo: _settingsBox.get('additional_info', defaultValue: []),
    );
  }

  void addPersonality(String item) {
    final personality = List<String>.from(state.personality)..add(item);
    _settingsBox.put('personality', personality);
    state = state.copyWith(personality: personality);
  }

  void updatePersonality(int index, String newItem) {
    if (index >= 0 && index < state.personality.length) {
      final personality = List<String>.from(state.personality);
      personality[index] = newItem;
      _settingsBox.put('personality', personality);
      state = state.copyWith(personality: personality);
    }
  }

  void deletePersonality(int index) {
    if (index >= 0 && index < state.personality.length) {
      final personality = List<String>.from(state.personality)..removeAt(index);
      _settingsBox.put('personality', personality);
      state = state.copyWith(personality: personality);
    }
  }

  void addAdditionalInfo(String item) {
    final additionalinfo = List<String>.from(state.additionalinfo)..add(item);
    _settingsBox.put('additional_info', additionalinfo);
    state = state.copyWith(additionalinfo: additionalinfo);
  }

  void updateAdditionalInfo(int index, String newItem) {
    if (index >= 0 && index < state.additionalinfo.length) {
      final additionalinfo = List<String>.from(state.additionalinfo);
      additionalinfo[index] = newItem;
      _settingsBox.put('additional_info', additionalinfo);
      state = state.copyWith(additionalinfo: additionalinfo);
    }
  }

  void deleteAdditionalInfo(int index) {
    if (index >= 0 && index < state.additionalinfo.length) {
      final additionalinfo = List<String>.from(state.additionalinfo)..removeAt(index);
      _settingsBox.put('additional_info', additionalinfo);
      state = state.copyWith(additionalinfo: additionalinfo);
    }
  }
}

final settingsPageViewModelProvider =
    NotifierProvider<SettingsPageViewModel, SettingsPageState>(
  () => SettingsPageViewModel(),
);
