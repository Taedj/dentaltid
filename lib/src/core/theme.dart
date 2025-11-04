import 'package:flutter/material.dart';

final darkTheme = ThemeData.dark().copyWith(
  // Define a dark theme as per PRD
  primaryColor: Colors.deepPurple,
  hintColor: Colors.deepPurpleAccent,
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[850],
  ),
  cardTheme: CardThemeData(
    color: Colors.grey[800],
  ),
);
