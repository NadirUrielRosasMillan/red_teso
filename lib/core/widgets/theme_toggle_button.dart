
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return IconButton(
          tooltip: isDark ? 'Activar tema claro' : 'Activar tema oscuro',
          onPressed: () => themeProvider.toggleTheme(),
          icon: Icon(
            isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
