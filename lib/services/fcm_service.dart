import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'package:arrendaoco/services/api_service.dart';

// Handler de segundo plano (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Notificación en Segundo Plano (FCM): ${message.messageId}");
}

class FCMService {
  static String? _fcmToken;
  static bool _firebaseInitialized = false;

  static Future<void> initialize(int usuarioId) async {
    // ---------------------------------------------------------
    // 1. ESCUCHA VIA REALTIME (Deshabilitado Supabase)
    // ---------------------------------------------------------
    print('ℹ️ FCMService: Escucha realtime vía Supabase deshabilitada');

    // ---------------------------------------------------------
    // 2. CONFIGURACIÓN FIREBASE (Para segundo plano / despertar)
    // ---------------------------------------------------------
    if (!_firebaseInitialized) {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }

        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Solicitar permisos
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ Permisos FCM concedidos.');
          _firebaseInitialized = true;

          // Obtener Token
          _fcmToken = await messaging.getToken();
          print('🔥 FCM Token: $_fcmToken');

          if (_fcmToken != null) {
            await _actualizarTokenEnLaravel(usuarioId, _fcmToken!);
          }

          // Listeners Firebase
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print(
              '🔔 (FCM) Mensaje recibido en foreground: ${message.messageId}',
            );

            if (message.notification != null) {
              NotificacionesService.mostrarNotificacion(
                titulo: message.notification!.title ?? 'Notificación',
                cuerpo: message.notification!.body ?? '',
              );
            }
          });

          // Background
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        } else {
          print('❌ Permisos FCM denegados.');
        }
      } catch (e) {
        print('⚠️ Error configurando Firebase: $e');
      }
    }
  }

  static Future<void> _actualizarTokenEnLaravel(int uid, String token) async {
    try {
      final api = ApiService();
      final response = await api.post('/fcm-token', data: {'fcm_token': token});
      if (response.statusCode == 200) {
        print('✅ FCM Token actualizado en Laravel');
      }
    } catch (e) {
      print('❌ Error enviando token FCM a Laravel: $e');
    }
  }

  static void dispose() {
    // No-op
  }
}
