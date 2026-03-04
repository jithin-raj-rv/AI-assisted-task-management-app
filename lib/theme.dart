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
  final Color visibleTextGradientStart;
  final Color visibleTextGradientEnd;
  final Color accentGradientStart;
  final Color accentGradientEnd;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;
  final bool isDarkMode; // Added to track dark mode
  final ToggleButtonsThemeData toggleButtonsTheme;
  final ElevatedButtonThemeData elevatedButtonTheme;

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
    required this.visibleTextGradientStart,
    required this.visibleTextGradientEnd,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.toggleButtonsTheme,
    required this.elevatedButtonTheme,
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
      textGradientEnd: const Color.fromARGB(255, 0, 122, 134),
      visibleTextGradientStart: Colors.deepOrange,
      visibleTextGradientEnd: Colors.deepPurpleAccent,
      accentGradientStart: Colors.blueGrey,
      accentGradientEnd: Colors.purple,
      backgroundGradientStart: Colors.cyanAccent,
      backgroundGradientEnd: Colors.blueGrey,
      isDarkMode: false,
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.purple,
        selectedColor: Colors.purple,
        fillColor: Colors.cyanAccent.withOpacity(0.2),
        borderColor: Colors.purple,
        selectedBorderColor: Colors.purple,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 2)),
          elevation: MaterialStateProperty.all(0),
        ),
      ),
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
      visibleTextGradientStart: Colors.orange,
      visibleTextGradientEnd: Colors.yellowAccent,
      accentGradientStart: Colors.purpleAccent,
      accentGradientEnd: Colors.tealAccent,
      backgroundGradientStart: Colors.purple,
      backgroundGradientEnd: Colors.blue,
      isDarkMode: true,
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.purpleAccent,
        selectedColor: Colors.tealAccent,
        fillColor: Colors.pink.withOpacity(0.2),
        borderColor: Colors.purpleAccent,
        selectedBorderColor: Colors.tealAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 2)),
          elevation: MaterialStateProperty.all(0),
        ),
      ),
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