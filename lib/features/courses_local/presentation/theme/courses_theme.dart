import 'package:flutter/material.dart';

/// Paleta del módulo de cursos: verde Nexus, blanco, gris y negro.
class CoursesColors {
  CoursesColors._();

  // Verdes Nexus
  static const Color green900 = Color(0xFF0B5D3B);
  static const Color green800 = Color(0xFF0B5D3B);
  static const Color green700 = Color(0xFF0B5D3B);
  static const Color green600 = Color(0xFF1E8449);
  static const Color green500 = Color(0xFF1E8449);
  static const Color green300 = Color(0xFFA8D5A2);
  static const Color green200 = Color(0xFFD5EAD2);
  static const Color green100 = Color(0xFFEAF4E8);
  static const Color green50 = Color(0xFFF5FAF4);

  // Grises y Negro
  static const Color ink = Color(0xFF111814);
  static const Color gray700 = Color(0xFF37413B);
  static const Color muted = Color(0xFF66756B);
  static const Color gray400 = Color(0xFF9CA8A0);
  static const Color line = Color(0xFFE0E5E2);
  static const Color gray100 = Color(0xFFF2F5F3);
  static const Color background = Color(0xFFFFFFFF);

  // Blanco
  static const Color white = Color(0xFFFFFFFF);

  static const Color primary = green900;
}

ThemeData coursesTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CoursesColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: CoursesColors.green300,
    onPrimary: CoursesColors.ink,
    secondary: CoursesColors.green600,
    onSecondary: CoursesColors.ink,
    surface: CoursesColors.white,
    onSurface: CoursesColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CoursesColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: CoursesColors.white,
      foregroundColor: CoursesColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoursesColors.green300,
        foregroundColor: CoursesColors.ink,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CoursesColors.green300,
        foregroundColor: CoursesColors.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
