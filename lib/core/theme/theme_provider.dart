import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool get isDarkMode => false;

  Future<void> toggleTheme() async {
    // El fondo del proyecto siempre se mantiene blanco por identidad visual.
    notifyListeners();
  }
}
