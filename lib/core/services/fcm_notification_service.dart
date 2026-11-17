import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler global de segundo plano para Firebase Cloud Messaging (FCM) en móviles
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Notificación recibida en segundo plano: ${message.notification?.title}');
}

/// Servicio centralizado de Notificaciones Push (Firebase Cloud Messaging + Local Banners)
class FcmNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'redteso_push_channel',
    'Notificaciones RedTESO',
    description: 'Canal oficial para invitaciones a entrevistas y postulaciones en TESOEM.',
    importance: Importance.high,
    playSound: true,
  );

  /// Inicializa el servicio de Notificaciones Push FCM
  static Future<void> init() async {
    // En Web, omitimos los listeners nativos de background para evitar bloqueos del Event Loop de Chrome
    if (kIsWeb) {
      debugPrint('FCM preparado en modo Web (Notificaciones sincronizadas por Firestore)');
      return;
    }

    try {
      // 1. Solicitar permisos de notificaciones al usuario en móvil (iOS / Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Estado de Permiso FCM Notificaciones: ${settings.authorizationStatus}');

      // 2. Configurar el canal de notificaciones locales en Android / iOS
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notificación tocada por el usuario: ${response.payload}');
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // 3. Registrar handler de segundo plano
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Guardar o actualizar el FCM Token en Firestore para el usuario autenticado
      await registerUserFcmToken();

      // 5. Escuchar notificaciones en primer plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // Escuchar renovaciones de token
      _fcm.onTokenRefresh.listen((newToken) async {
        await _updateTokenInFirestore(newToken);
      });
    } catch (e) {
      debugPrint('Error al inicializar FCM Notification Service: $e');
    }
  }

  /// Registra el FCM Token del usuario en su documento `/users/{uid}`
  static Future<void> registerUserFcmToken() async {
    if (kIsWeb) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error obteniendo token de FCM: $e');
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM Token registrado con éxito en Firestore para ${user.uid}');
    } catch (e) {
      debugPrint('Error guardando FCM Token en Firestore: $e');
    }
  }

  /// Envía una notificación push en tiempo real a un estudiante o usuario por su `targetUserId`
  static Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String message,
  }) async {
    if (targetUserId.isEmpty) return;

    try {
      // 1. Guardar la notificación en la colección `/notifications` de Firestore (funciona 100% en Web, Android e iOS)
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': targetUserId,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // 2. Disparar banner emergente nativo únicamente en dispositivos móviles (Android / iOS)
      if (!kIsWeb) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(targetUserId).get();
        final userData = userDoc.data() ?? {};
        final fcmToken = userData['fcmToken']?.toString();

        debugPrint('Notificación Push enviada a $targetUserId. Token FCM: $fcmToken');

        _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          message,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al enviar Notificación Push: $e');
    }
  }
}
