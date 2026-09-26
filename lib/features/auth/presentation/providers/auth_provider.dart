import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';

enum UserType { alumno, empresa, admin, none }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  UserType _userType = UserType.none;
  User? _user;
  Timer? _timer;

  bool get isLoading => _isLoading;
  UserType get userType => _userType;
  
  // Requisito: Solo está logueado si el correo está verificado
  bool get isLoggedIn => _user != null && _user!.emailVerified;
  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null && user.emailVerified) {
        await _fetchUserType(user.uid);
      } else {
        _userType = UserType.none;
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserType(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final typeStr = doc.data()?['type'] as String?;
        _userType = UserType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => UserType.none,
        );
      }
    } catch (e) {
      debugPrint('Error fetching user type: $e');
    }
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // SOLUCCIÓN AL PROBLEMA DE CARGA: Al registrarse, Firebase inicia sesión automáticamente
      // dejando un estado "no verificado" en caché. Cerramos sesión antes para obligar un inicio limpio.
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (!credential.user!.emailVerified) {
        _isLoading = false;
        notifyListeners();
        return "Tu correo electrónico no ha sido verificado. Por favor revisa tu bandeja de entrada.";
      }

      _user = credential.user; // Asignamos la instancia fresca con la verificación actualizada
      await _fetchUserType(credential.user!.uid);
      
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar correo de verificación
      await credential.user!.sendEmailVerification();

      // Guardar datos en Firestore
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pendiente',
        'emailVerified': false,
        ...?extraData,
      });

      // Cerramos la sesión automática del registro para que al volver al login esté limpio
      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
      return null; 
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Método para checar manualmente la verificación (útil para la UI)
  Future<void> checkVerificationStatus() async {
    await _auth.currentUser?.reload();
    _user = _auth.currentUser;
    if (_user?.emailVerified ?? false) {
      await _fetchUserType(_user!.uid);
      await _db.collection('users').doc(_user!.uid).update({'emailVerified': true});
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = false;
    _userType = UserType.none;
    _timer?.cancel();
    await _auth.signOut();
    notifyListeners();
  }
}
