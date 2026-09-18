import 'package:flutter/material.dart';

/// Cinematic dark palette from the Star Studio design doc (§5.1).
class StudioColors {
  static const background = Color(0xFF12100E);
  static const surface = Color(0xFF17110F);
  static const gold = Color(0xFFFFC857);
  static const goldMuted = Color(0xFFD4A052);
  static const teal = Color(0xFF4ECDC4);
  static const coral = Color(0xFFFF6B6B);
  static const textPrimary = Color(0xFFF5EFE6);
  static const textSecondary = Color(0xFFB8AFA3);
}

ThemeData buildStudioTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: StudioColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: StudioColors.gold,
      secondary: StudioColors.teal,
      error: StudioColors.coral,
      surface: StudioColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: StudioColors.textPrimary,
      displayColor: StudioColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: StudioColors.background,
      elevation: 0,
    ),
  );
}
