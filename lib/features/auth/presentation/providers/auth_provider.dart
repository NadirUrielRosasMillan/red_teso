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

  bool get isLoading => _isLoading;
  UserType get userType => _userType;
  bool get isLoggedIn => _user != null;
  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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

      // 👇 FIX 1: Fijamos el usuario y el tipo INMEDIATAMENTE
      //    para que el AuthWrapper reaccione al instante,
      //    sin esperar a la escritura de Firestore.
      _user = credential.user;
      _userType = UserType.values.firstWhere(
            (e) => e.toString().split('.').last == type,
        orElse: () => UserType.none,
      );

      // 👇 FIX 2: Damos tiempo a que el token de Auth
      //    se propague al SDK de Firestore antes de escribir.
      await Future.delayed(const Duration(milliseconds: 500));

      // 👇 FIX 3: Escritura con timeout para no quedar colgado
      //    si Firestore no responde.
      try {
        await _db
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'type': type,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Pendiente',
          ...?extraData,
        })
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Error al escribir en Firestore: $e');
        // Aun si falla la escritura, dejamos pasar al usuario.
        // Puedes reintentar la escritura más tarde o mostrarlo en logs.
      }

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

  Future<void> logout() async {
    _isLoading = false;
    _userType = UserType.none;
    await _auth.signOut();
    notifyListeners();
  }
}
