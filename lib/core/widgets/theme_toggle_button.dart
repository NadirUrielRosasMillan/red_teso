import 'package:flutter/material.dart';

/// El tema de la aplicación mantiene siempre fondo blanco.
class ThemeToggleButton extends StatelessWidget {
  final Color? color;

  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
