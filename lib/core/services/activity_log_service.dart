import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado de auditoría y log de actividad en tiempo real
class ActivityLogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Registra una acción de usuario en Firestore (/activity_logs)
  static Future<void> logActivity({
    required String action,
    String? details,
    String status = 'Activo',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final name = userData['name'] ?? user.displayName ?? user.email ?? 'Usuario TESOEM';
      final type = userData['userType'] ?? userData['type'] ?? 'usuario';

      await _db.collection('activity_logs').add({
        'userId': user.uid,
        'userName': name,
        'userEmail': user.email ?? '',
        'userType': type,
        'action': action,
        'details': details ?? '',
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Log de Actividad registrado: [$type] $name -> $action');
    } catch (e) {
      debugPrint('Error registrando log de actividad: $e');
    }
  }
}
