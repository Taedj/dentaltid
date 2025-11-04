import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTheme { dark, light, blue, green }

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(AppTheme.dark);

  void setTheme(AppTheme theme) {
    state = theme;
  }
}

final appThemes = {
  AppTheme.dark: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple[800], // Adjust to fit new scheme
    ),
    cardTheme: CardThemeData(
      color: Colors.deepPurple[700], // Adjust to fit new scheme
    ),
  ),
  AppTheme.light: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
    cardTheme: const CardThemeData(color: Colors.white),
  ),
  AppTheme.blue: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A192F)),
    cardTheme: const CardThemeData(color: Color(0xFF172A45)),
  ),
  AppTheme.green: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A2F19)),
    cardTheme: const CardThemeData(color: Color(0xFF17452A)),
  ),
};
