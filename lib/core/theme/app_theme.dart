import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de ÁGORA Talento: azul y blanco.
class AppTheme {
  static const Color deepBlue = Color(0xFF12366A);
  static const Color primaryColor = Color(0xFF164B91);
  static const Color secondaryColor = Color(0xFF3679C9);
  static const Color accentColor = Color(0xFF8DB9E8);
  static const Color lightBlue = Color(0xFFDCEBFA);
  static const Color paleBlue = Color(0xFFF1F6FC);
  static const Color backgroundColor = Colors.white;
  static const Color greyColor = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF64748B);

  // Alias para mantener compatibilidad con pantallas existentes durante la migración.
  static const Color primaryGreen = primaryColor;
  static const Color accentGreen = secondaryColor;
  static const Color darkGreen = deepBlue;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: Colors.white,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: deepBlue, elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE4EDF7))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paleBlue,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDCE7F3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDCE7F3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
        labelStyle: const TextStyle(color: greyColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: secondaryColor, foregroundColor: Colors.white),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark, primary: const Color(0xFF8DB9E8), secondary: const Color(0xFF6EA5E3), tertiary: accentColor, surface: const Color(0xFF101C2D));
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1524),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101C2D), foregroundColor: Colors.white, elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(color: const Color(0xFF15243A), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF294363)))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF15243A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF294363))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF294363))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFFB8C8DC)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: secondaryColor, foregroundColor: Colors.white),
    );
  }
}
