import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler de segundo plano (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Notificación en Segundo Plano (FCM): ${message.messageId}");
  // Aquí el sistema operativo suele encargarse de la notificación visual si lleva "notification" payload.
}

class FCMService {
  static String? _fcmToken;
  static RealtimeChannel? _supabaseChannel;
  static bool _firebaseInitialized = false;

  static Future<void> initialize(int usuarioId) async {
    // ---------------------------------------------------------
    // 1. ESCUCHA VIA SUPABASE REALTIME (Para primer plano inmediato)
    // ---------------------------------------------------------
    if (_supabaseChannel == null) {
      print(
        '🔔 Iniciando escucha Realtime (Supabase) para usuario: $usuarioId',
      );
      _supabaseChannel = Supabase.instance.client
          .channel('public:notificaciones:$usuarioId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notificaciones',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'usuario_id',
              value: usuarioId,
            ),
            callback: (payload) {
              print('🔔 Notificación Realtime recibida: ${payload.newRecord}');
              final data = payload.newRecord;

              // Mostrar alerta local
              NotificacionesService.mostrarNotificacion(
                titulo: data['titulo'] ?? 'Nueva notificación',
                cuerpo: data['mensaje'] ?? 'Tienes un nuevo mensaje',
              );
            },
          )
          .subscribe();
    }

    // ---------------------------------------------------------
    // 2. CONFIGURACIÓN FIREBASE (Para segundo plano / despertar)
    // ---------------------------------------------------------
    if (!_firebaseInitialized) {
      try {
        // Inicializar si no se hizo en main (redundante pero seguro)
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
            await _actualizarTokenEnSupabase(usuarioId, _fcmToken!);
          }

          // Listeners Firebase
          // Solo para logear, ya que Supabase Realtime maneja la UI en foreground
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print(
              '🔔 (FCM) Mensaje recibido en foreground: ${message.messageId}',
            );
            // Opcional: Si implementas deduplicación, podrías mostrarlo aquí si Supabase falla.
            // Por ahora confiamos en Supabase Realtime para la UI activa.
          });

          // Background
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        } else {
          print('❌ Permisos FCM denegados.');
        }
      } catch (e) {
        print(
          '⚠️ Error configurando Firebase (posible falta de google-services.json): $e',
        );
      }
    }
  }

  static Future<void> _actualizarTokenEnSupabase(int uid, String token) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'fcm_token': token})
          .eq('id', uid);
      print('☁️ Token FCM guardado en Supabase para usuario $uid');
    } catch (e) {
      print('⚠️ Error guardando token FCM: $e');
    }
  }

  static void dispose() {
    if (_supabaseChannel != null) {
      Supabase.instance.client.removeChannel(_supabaseChannel!);
      _supabaseChannel = null;
    }
  }
}
