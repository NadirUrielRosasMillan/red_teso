import 'package:flutter/material.dart';

enum UserType { alumno, empresa, none }

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  UserType _userType = UserType.none;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  UserType get userType => _userType;

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulación de delay de red
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'alumno' && password == '123') {
      _isLoggedIn = true;
      _userType = UserType.alumno;
      _isLoading = false;
      notifyListeners();
      return null;
    } else if (email == 'empresa' && password == '123') {
      _isLoggedIn = true;
      _userType = UserType.empresa;
      _isLoading = false;
      notifyListeners();
      return null;
    } else {
      _isLoading = false;
      notifyListeners();
      return "Credenciales incorrectas (Prueba con alumno/123)";
    }
  }

  // Añadimos de nuevo el método signUp que faltaba para corregir el error de compilación
  Future<String?> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulación de delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Simulamos registro exitoso como alumno por defecto para pruebas visuales
    _isLoggedIn = true;
    _userType = UserType.alumno;
    _isLoading = false;
    notifyListeners();
    return null;
  }

  void logout() {
    _isLoggedIn = false;
    _userType = UserType.none;
    notifyListeners();
  }
}
