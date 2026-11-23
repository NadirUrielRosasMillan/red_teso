import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de NEXUS: paleta oficial verde Nexus, blanco, gris y negro.
class AppTheme {
  // --- Paleta Oficial NEXUS ---
  static const Color nexusGreen = Color(0xFF0B5D3B);
  static const Color nexusGreenSecondary = Color(0xFF1E8449);
  static const Color nexusGreenLight = Color(0xFFA8D5A2);
  static const Color nexusTextMuted = Color(0xFF66756B);

  // --- Neutros (Blanco, Gris, Negro) ---
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF6F8F7);
  static const Color borderLight = Color(0xFFE0E5E2);
  static const Color textPrimaryLight = Color(0xFF111814);
  static const Color textSecondaryLight = nexusTextMuted;
  static const Color greyColor = nexusTextMuted;
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // --- Colores Principales del Tema ---
  static const Color primaryColor = nexusGreen;
  static const Color secondaryColor = nexusGreenSecondary;
  static const Color accentColor = nexusGreenLight;
  static const Color darkGreen = nexusGreen;

  // --- Alias de compatibilidad (sin azul/turquesa, redirigidos a paleta Nexus/Blanco) ---
  static const Color primaryGreen = nexusGreen;
  static const Color accentGreen = nexusGreenLight;
  static const Color primaryTurquoise = nexusGreen;
  static const Color darkTurquoise = nexusGreen;
  static const Color accentCyan = nexusGreenSecondary;
  static const Color cyan = nexusGreenSecondary;
  static const Color primaryBlue = nexusGreen;
  static const Color successMint = nexusGreenLight;

  // --- Alias de modo oscuro redirigidos a fondo blanco y grises limpios ---
  static const Color bgDark = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFF6F8F7);
  static const Color borderDark = Color(0xFFE0E5E2);
  static const Color textPrimaryDark = Color(0xFF111814);
  static const Color textSecondaryDark = nexusTextMuted;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: nexusGreen,
      brightness: Brightness.light,
      primary: nexusGreen,
      onPrimary: Colors.black,
      secondary: nexusGreenSecondary,
      onSecondary: Colors.black,
      tertiary: nexusGreenLight,
      onTertiary: Colors.black,
      surface: Colors.white,
      onSurface: textPrimaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textPrimaryLight,
        displayColor: textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: nexusGreenLight,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: nexusGreenLight,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: nexusGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          borderSide: const BorderSide(color: nexusGreen, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: nexusGreenLight,
        foregroundColor: Colors.black,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
