// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppThemeState {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quatenery;
  final Color background;
  final Color foreground;
  final Color actionGradientStart;
  final Color actionGradientEnd;
  final Color textGradientStart;
  final Color textGradientEnd;
  final Color accentGradientStart;
  final Color accentGradientEnd;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;
  final bool isDarkMode; // Added to track dark mode

  AppThemeState({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quatenery,
    required this.background,
    required this.foreground,
    required this.actionGradientStart,
    required this.actionGradientEnd,
    required this.textGradientStart,
    required this.textGradientEnd,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    this.isDarkMode = false,
  });

  // Factory method to create light theme
  factory AppThemeState.light() {
    return AppThemeState(
      primary: Colors.blue,
      secondary: Colors.purpleAccent,
      tertiary: Colors.orange,
      quatenery: Colors.cyanAccent,
      background: Colors.white,
      foreground: Colors.black,
      actionGradientStart: Colors.purple,
      actionGradientEnd: Colors.lightBlueAccent,
      textGradientStart: Colors.purple,
      textGradientEnd: Color.fromARGB(255, 0, 122, 134),
      accentGradientStart: Colors.blueGrey,
      accentGradientEnd: Colors.purple,
      backgroundGradientStart: Colors.cyanAccent,
      backgroundGradientEnd: Colors.blueGrey,
      isDarkMode: false,
    );
  }

  // Factory method to create dark theme
  factory AppThemeState.dark() {
    return AppThemeState(
      primary: Colors.deepPurple,
      secondary: Colors.teal,
      tertiary: Colors.indigo,
      quatenery: Colors.pink,
      background: Colors.black,
      foreground:Colors.white,
      actionGradientStart: Colors.teal,
      actionGradientEnd: Colors.purpleAccent,
      textGradientStart: Colors.purpleAccent,
      textGradientEnd: Colors.teal,
      accentGradientStart: Colors.purpleAccent,
      accentGradientEnd: Colors.tealAccent,
      backgroundGradientStart: Colors.purple,
      backgroundGradientEnd: Colors.blue,
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