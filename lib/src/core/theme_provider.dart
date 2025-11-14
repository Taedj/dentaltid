import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/theme.dart'; // Import the centralized themes

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
  AppTheme.dark: darkTheme, // Use the imported darkTheme
  AppTheme.light: lightTheme, // Use the imported lightTheme
  AppTheme.blue: ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.cyanAccent,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  AppTheme.green: ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.lightGreenAccent,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
};
