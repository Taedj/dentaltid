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
    primaryColor: Colors.deepPurpleAccent,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF311B92),
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF4527A0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  AppTheme.light: ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  AppTheme.blue: ThemeData.dark().copyWith(
    primaryColor: Colors.cyanAccent,
    scaffoldBackgroundColor: const Color(0xFF0A192F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A192F),
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF172A45),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  AppTheme.green: ThemeData.dark().copyWith(
    primaryColor: Colors.lightGreenAccent,
    scaffoldBackgroundColor: const Color(0xFF0A2F19),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A2F19),
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF17452A),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
};
