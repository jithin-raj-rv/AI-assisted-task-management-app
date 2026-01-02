// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppThemeState {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color primaryGradient1;
  final Color primaryGradient2;
  final Color secondaryGradient1;
  final Color secondaryGradient2;
  final Color tertiaryGradient1;
  final Color tertiaryGradient2;
  final Color backgroundGradient1;
  final Color backgroundGradient2;
  final bool isDarkMode; // Added to track dark mode

  AppThemeState({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.primaryGradient1,
    required this.primaryGradient2,
    required this.secondaryGradient1,
    required this.secondaryGradient2,
    required this.tertiaryGradient1,
    required this.tertiaryGradient2,
    required this.backgroundGradient1,
    required this.backgroundGradient2,
    this.isDarkMode = false,
  });

  // Factory method to create light theme
  factory AppThemeState.light() {
    return AppThemeState(
      primary: Colors.blue,
      secondary: Colors.purpleAccent,
      tertiary: Colors.orange,
      background: Colors.white,
      primaryGradient1: Colors.purple,
      primaryGradient2: Colors.lightBlueAccent,
      secondaryGradient1: Colors.lightBlue,
      secondaryGradient2: Colors.purpleAccent,
      tertiaryGradient1: Colors.orange,
      tertiaryGradient2: Colors.orangeAccent,
      backgroundGradient1: Colors.white,
      backgroundGradient2: Colors.blueGrey,
      isDarkMode: false,
    );
  }

  // Factory method to create dark theme
  factory AppThemeState.dark() {
    return AppThemeState(
      primary: Colors.deepPurple,
      secondary: Colors.deepPurple,
      tertiary: Colors.indigo,
      background: Colors.black,
      primaryGradient1: Colors.teal,
      primaryGradient2: Colors.purpleAccent,
      secondaryGradient1: Colors.purpleAccent,
      secondaryGradient2: Colors.tealAccent,
      tertiaryGradient1: Colors.indigo,
      tertiaryGradient2: Colors.indigoAccent,
      backgroundGradient1: Colors.black,
      backgroundGradient2: Colors.deepPurple,
      isDarkMode: true,
    );
  }
}

class ThemeNotifier extends Notifier<AppThemeState> {
  Box get _myBox => Hive.box('boxx'); // Access the Hive box lazily

  @override
  AppThemeState build() {
    return _loadTheme();
  }

  AppThemeState _loadTheme() {
    final storedDarkMode = _myBox.get('isDarkMode', defaultValue: false);
    if (storedDarkMode) {
      return AppThemeState.dark();
    } else {
      return AppThemeState.light();
    }
  }

  void toggleTheme() {
    if (state.isDarkMode) {
      state = AppThemeState.light();
    } else {
      state = AppThemeState.dark();
    }
    _myBox.put('isDarkMode', state.isDarkMode); // Persist the theme preference
  }

  void setTheme(AppThemeState newTheme) {
    state = newTheme;
    _myBox.put('isDarkMode', state.isDarkMode);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeState>(
  () => ThemeNotifier(),
);