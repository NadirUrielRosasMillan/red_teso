import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Colores adaptativos según el tema activo (claro / oscuro).
///
/// Uso: `context.textPrimary`, `context.cardColor`, `context.isDark`...
/// Evita escribir colores fijos como `Colors.white` o `Color(0xFF0F172A)`
/// en las pantallas para que el modo oscuro funcione en toda la app.
extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Fondo general de la pantalla.
  Color get bgColor => isDark ? AppTheme.bgDark : AppTheme.surfaceLight;

  /// Fondo de tarjetas, formularios y diálogos.
  Color get cardColor => isDark ? AppTheme.surfaceDark : Colors.white;

  /// Fondo de campos de texto.
  Color get fieldColor => isDark ? const Color(0xFF153443) : const Color(0xFFF8FCFE);

  /// Fondo de chips / etiquetas no seleccionadas.
  Color get chipColor => isDark ? const Color(0xFF153443) : const Color(0xFFF0F8FA);

  /// Texto principal (títulos, nombres).
  Color get textPrimary => isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

  /// Texto secundario (subtítulos, descripciones).
  Color get textSecondary => isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

  /// Bordes y divisores.
  Color get borderColor => isDark ? AppTheme.borderDark : AppTheme.borderLight;

  /// AppBar de los paneles: turquesa en claro, pizarra en oscuro.
  /// En ambos casos el contenido del AppBar va en blanco.
  Color get appBarColor =>
      isDark ? AppTheme.bgDark.withValues(alpha: 0.92) : AppTheme.primaryTurquoise;

  /// Color de acento legible sobre el fondo actual.
  Color get accent => isDark ? AppTheme.accentCyan : AppTheme.primaryTurquoise;
}
