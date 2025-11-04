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
  AppTheme.dark: ThemeData.dark().copyWith(
    primaryColor: Colors.deepPurple,
    hintColor: Colors.deepPurpleAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[800],
    ),
  ),
  AppTheme.light: ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    hintColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
    ),
  ),
  AppTheme.blue: ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A192F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A192F),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF172A45),
    ),
  ),
  AppTheme.green: ThemeData(
    primarySwatch: Colors.green,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A2F19),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A2F19),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF17452A),
    ),
  ),
};
