import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores oficiales del Sistema Nacional de Diseño (México)
  static const Color primaryColor = Color(0xFF691C32); // Guinda
  static const Color secondaryColor = Color(0xFF98984A); // Dorado/Verde seco
  static const Color accentColor = Color(0xFFBE965B); // Oro
  static const Color darkGreen = Color(0xFF13322B); // Verde oscuro institucional
  static const Color backgroundColor = Colors.white;
  static const Color greyColor = Color(0xFF6F7271); // Gris institucional

  // Aliases de compatibilidad para aplicar los nuevos colores oficiales en toda la app sin romper el código anterior
  static const Color primaryGreen = primaryColor; // Ahora todo lo verde usa el Guinda oficial
  static const Color accentGreen = accentColor;   // Ahora los acentos usan el Oro institucional

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        onPrimary: Colors.white,
        surface: backgroundColor,
        outline: greyColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4C19C)), // Tono dorado suave
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: greyColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
