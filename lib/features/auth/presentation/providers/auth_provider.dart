import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/services/activity_log_service.dart';

enum UserType { alumno, empresa, admin, profesor, none }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance {
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthState,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Error escuchando el estado de autenticación: $error');
        _isInitializing = false;
        notifyListeners();
      },
    );
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = false;
  bool _isInitializing = true;
  UserType _userType = UserType.none;
  User? _user;
  Timer? _timer;

  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  UserType get userType => _userType;
  User? get user => _user;

  /// Los usuarios normales requieren correo verificado.
  /// El administrador debe tener una cuenta autenticada y un perfil admin válido.
  bool get isLoggedIn =>
      _user != null &&
      (_user!.emailVerified || _userType == UserType.admin);

  Future<void> _handleAuthState(User? user) async {
    _user = user;

    if (user == null) {
      _userType = UserType.none;
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    // No confiar en el rol guardado en memoria: consultar el perfil de Firestore.
    await _fetchUserType(user.uid);

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> _fetchUserType(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        _userType = UserType.none;
        return;
      }

      final data = doc.data() ?? <String, dynamic>{};
      final rawType = (data['type'] ?? data['userType'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      _userType = UserType.values.firstWhere(
        (type) => type.name == rawType,
        orElse: () => UserType.none,
      );
    } on FirebaseException catch (e) {
      // Si las reglas impiden leer el perfil, no elevar privilegios.
      debugPrint('No se pudo consultar el tipo de usuario (${e.code}): ${e.message}');
      _userType = UserType.none;
    } catch (e) {
      debugPrint('Error consultando el tipo de usuario: $e');
      _userType = UserType.none;
    }
  }

  Future<String?> signIn(String email, String password) async {
    _setLoading(true);

    try {
      // Evita mantener una sesión anterior antes de autenticar otra cuenta.
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return 'Firebase no devolvió un usuario válido.';
      }

      await user.reload();
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return 'No se pudo recuperar la sesión. Intenta nuevamente.';
      }

      _user = currentUser;
      await _fetchUserType(currentUser.uid);

      if (!currentUser.emailVerified && _userType != UserType.admin) {
        await _auth.signOut();
        _user = null;
        _userType = UserType.none;
        return 'Tu correo electrónico no ha sido verificado. Revisa tu bandeja de entrada.';
      }

      try {
        await ActivityLogService.logActivity(
          action: 'Inició sesión en la plataforma',
          status: 'Activo',
        );
      } catch (e) {
        // El fallo del registro de actividad no debe bloquear el login.
        debugPrint('No se pudo registrar el inicio de sesión: $e');
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } on FirebaseException catch (e) {
      debugPrint('Error de Firebase durante el inicio de sesión: ${e.code} ${e.message}');
      return 'No se pudo consultar tu perfil. Revisa las reglas de Firestore (${e.code}).';
    } catch (e) {
      debugPrint('Error durante el inicio de sesión: $e');
      return 'Ocurrió un error al iniciar sesión. Intenta nuevamente.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    _setLoading(true);

    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return 'Firebase no devolvió un usuario válido.';
      }

      await user.sendEmailVerification();

      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'type': type.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pendiente',
        'emailVerified': false,
        ...?extraData,
      });

      // Cierra la sesión creada automáticamente tras el registro.
      await _auth.signOut();
      _user = null;
      _userType = UserType.none;

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } on FirebaseException catch (e) {
      debugPrint('Error de Firestore durante el registro: ${e.code} ${e.message}');
      return 'La cuenta se creó, pero no se pudieron guardar sus datos (${e.code}).';
    } catch (e) {
      debugPrint('Error durante el registro: $e');
      return 'Ocurrió un error al registrar la cuenta.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkVerificationStatus() async {
    final current = _auth.currentUser;
    if (current == null) {
      _user = null;
      _userType = UserType.none;
      notifyListeners();
      return;
    }

    try {
      await current.reload();
      final refreshedUser = _auth.currentUser;
      _user = refreshedUser;

      if (refreshedUser != null) {
        await _fetchUserType(refreshedUser.uid);

        if (refreshedUser.emailVerified) {
          try {
            await _db.collection('users').doc(refreshedUser.uid).update({
              'emailVerified': true,
            });
          } on FirebaseException catch (e) {
            // No invalidar la verificación local si la escritura está prohibida.
            debugPrint('No se pudo actualizar emailVerified en Firestore: ${e.code}');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('No se pudo comprobar la verificación: ${e.code}');
    } finally {
      notifyListeners();
    }
  }

  /// Inicia sesión con una cuenta de administrador PREVIAMENTE creada.
  /// No crea cuentas privilegiadas automáticamente ni concede el rol en caso de error.
  Future<String?> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return 'No se pudo autenticar la cuenta de administrador.';
      }

      _user = user;
      await _fetchUserType(user.uid);

      if (_userType != UserType.admin) {
        await _auth.signOut();
        _user = null;
        _userType = UserType.none;
        return 'La cuenta está autenticada, pero no tiene el rol de administrador autorizado.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } on FirebaseException catch (e) {
      debugPrint('Error consultando perfil admin: ${e.code} ${e.message}');
      return 'No se pudo verificar el rol de administrador (${e.code}).';
    } catch (e) {
      debugPrint('Error iniciando sesión como administrador: $e');
      return 'No se pudo iniciar sesión como administrador.';
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra Firebase Auth aunque falle el registro de actividad.
  Future<void> logout() async {
    _timer?.cancel();
    _timer = null;

    try {
      try {
        await ActivityLogService.logActivity(
          action: 'Salió de la aplicación',
          status: 'Inactivo',
        );
      } catch (e) {
        debugPrint('No se pudo registrar la salida: $e');
      }
    } finally {
      try {
        await _auth.signOut();
      } finally {
        _user = null;
        _userType = UserType.none;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'No se pudo conectar. Revisa tu conexión a internet.';
      default:
        return e.message ?? 'Error de autenticación (${e.code}).';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
