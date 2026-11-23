import 'package:flutter/material.dart';

/// Paleta del modulo de cursos: solo verdes, grises y blanco.
class CoursesColors {
  CoursesColors._();

  // Verdes
  static const Color green900 = Color(0xFF0F3D2A);
  static const Color green800 = Color(0xFF14532F);
  static const Color green700 = Color(0xFF1B6B45);
  static const Color green600 = Color(0xFF2E8B57);
  static const Color green500 = Color(0xFF3FA56B);
  static const Color green300 = Color(0xFF8CCFA8);
  static const Color green200 = Color(0xFFC9E8D6);
  static const Color green100 = Color(0xFFE3F4EA);
  static const Color green50 = Color(0xFFF2FAF5);

  // Grises
  static const Color ink = Color(0xFF1F2933);
  static const Color gray700 = Color(0xFF3E4C59);
  static const Color muted = Color(0xFF616E7C);
  static const Color gray400 = Color(0xFF9AA5B1);
  static const Color line = Color(0xFFD9DEE3);
  static const Color gray100 = Color(0xFFEEF1F4);
  static const Color background = Color(0xFFF6F8F7);

  // Blanco
  static const Color white = Color(0xFFFFFFFF);

  static const Color primary = green600;
}

ThemeData coursesTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CoursesColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: CoursesColors.green600,
    onPrimary: CoursesColors.white,
    surface: CoursesColors.white,
    onSurface: CoursesColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CoursesColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: CoursesColors.white,
      foregroundColor: CoursesColors.ink,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoursesColors.green600,
        foregroundColor: CoursesColors.white,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}
