import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de ÁGORA Talento: azul y blanco.
class AppTheme {
<<<<<<< HEAD
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
=======
  static const Color primaryColor = Color(0xFF0793B8); // Turquesa Principal
  static const Color secondaryColor = Color(0xFF10BFD0); // Cian
  static const Color accentColor = Color(0xFF6BE7C8); // Menta
  static const Color darkGreen = Color(0xFF056C88); // Turquesa Profundo
  static const Color backgroundColor = Color(0xFFF8FBFF); // Fondo claro limpio
  static const Color greyColor = Color(0xFF566080); // Gris 600

  // --- Dark Theme Colors (Turquesa / Slate Teal) ---
  static const Color bgDark = Color(0xFF0A1922); // Pizarra Turquesa Oscuro
  static const Color surfaceDark = Color(0xFF112A36); // Superficie Turquesa Oscura
  static const Color borderDark = Color(0xFF1B4B5F); // Borde Turquesa Oscuro
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Blanco
  static const Color textSecondaryDark = Color(0xFFB8E2EC); // Cian-200 (texto secundario)

  // --- Light Theme Colors ---
  static const Color bgLight = Color(0xFFFFFFFF); // Blanco puro
  static const Color bgWhite = bgLight; // Alias para fondo blanco
  static const Color surfaceLight = Color(0xFFF4FAFC); // Turquesa-50 (superficie muy clara)
  static const Color borderLight = Color(0xFFDCEBF0); // Borde Turquesa-Gris claro
  static const Color textPrimaryLight = Color(0xFF0D212C); // Pizarra-950
  static const Color textSecondaryLight = Color(0xFF4A6572); // Pizarra-600

  // --- Colores Principales (Brand) ---
  static const Color primaryTurquoise = Color(0xFF0793B8); // Cian-600 (Turquesa Principal)
  static const Color darkTurquoise = Color(0xFF056C88); // Cian-800 (Turquesa Oscuro)
  static const Color accentCyan = Color(0xFF10BFD0); // Cian-400 (Acentos)
  static const Color primaryBlue = Color(0xFF0793B8); // Redirigido a Turquesa para unificar todo
  static const Color successMint = Color(0xFF6BE7C8); // Menta (Éxito)

  // Compatibilidad hacia atrás (alias)
  static const Color primaryGreen = primaryTurquoise; 
  static const Color accentGreen = accentCyan;
  static const Color cyan = accentCyan;
>>>>>>> origin/main

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryTurquoise,
      brightness: Brightness.light,
      primary: primaryTurquoise,
      secondary: secondaryColor,
      tertiary: accentColor,
<<<<<<< HEAD
      surface: Colors.white,
=======
      surface: surfaceLight,
>>>>>>> origin/main
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
<<<<<<< HEAD
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
=======
      scaffoldBackgroundColor: surfaceLight,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTurquoise, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
      ),
>>>>>>> origin/main
    );
  }

  static ThemeData get darkTheme {
<<<<<<< HEAD
    final scheme = ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark, primary: const Color(0xFF8DB9E8), secondary: const Color(0xFF6EA5E3), tertiary: accentColor, surface: const Color(0xFF101C2D));
=======
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryTurquoise,
      brightness: Brightness.dark,
      primary: accentCyan,
      secondary: primaryTurquoise,
      tertiary: accentColor,
      surface: surfaceDark,
    );

>>>>>>> origin/main
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
<<<<<<< HEAD
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
=======
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF153443),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: accentCyan,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
>>>>>>> origin/main
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: secondaryColor, foregroundColor: Colors.white),
    );
  }
}
