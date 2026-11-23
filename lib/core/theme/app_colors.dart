import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Colores unificados NEXUS: fondo siempre blanco, acentos verdes Nexus, grises y negro.
extension AppThemeColors on BuildContext {
  bool get isDark => false;

  /// Fondo general de la pantalla (siempre blanco).
  Color get bgColor => Colors.white;

  /// Fondo de tarjetas, formularios y diálogos.
  Color get cardColor => Colors.white;

  /// Fondo de campos de texto.
  Color get fieldColor => const Color(0xFFF6F8F7);

  /// Fondo de chips / etiquetas no seleccionadas.
  Color get chipColor => const Color(0xFFF2F5F3);

  /// Texto principal (títulos, nombres).
  Color get textPrimary => AppTheme.textPrimaryLight;

  /// Texto secundario (subtítulos, descripciones).
  Color get textSecondary => AppTheme.textSecondaryLight;

  /// Bordes y divisores.
  Color get borderColor => AppTheme.borderLight;

  /// AppBar de los paneles: fondo blanco limpio.
  Color get appBarColor => Colors.white;

  /// Color de acento legible sobre el fondo blanco.
  Color get accent => AppTheme.nexusGreen;
}
