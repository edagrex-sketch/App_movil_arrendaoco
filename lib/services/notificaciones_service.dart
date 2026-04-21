import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:arrendaoco/model/bd.dart';

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  /// Inicializar el servicio de notificaciones
  static Future<void> inicializar() async {
    if (_inicializado) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar cuando el usuario toca la notificación
        print('Notificación tocada: ${response.payload}');
      },
    );

    // Solicitar permisos específicamente para Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _inicializado = true;
  }

  /// Configurar Firebase Cloud Messaging (FCM)
  static Future<void> configurarFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Solicitar permisos (iOS y Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');
    } else {
      print('⚠️ Permiso de notificaciones denegado');
    }

    // 2. Obtener Token (Para enviarlo al backend)
    String? token = await messaging.getToken();
    print('📱 FCM Token: $token');
    // TODO: Enviar este token a Laravel cuando el usuario inicie sesión

    // 3. Listener en Primer Plano (App abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Mensaje en primer plano: ${message.notification?.title}');
      
      if (message.notification != null) {
        mostrarNotificacion(
          titulo: message.notification!.title ?? 'Nueva Notificación',
          cuerpo: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // 4. Listener cuando se abre la App desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🖱️ App abierta desde notificación: ${message.data}');
    });
  }

  /// Manejador de mensajes en segundo plano (DEBE ser una función de alto nivel)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Inicializar Firebase si es necesario para manejar la lógica
    print('💤 Mensaje en segundo plano: ${message.messageId}');
  }

  /// Mostrar notificación inmediata
  static Future<void> mostrarNotificacion({
    required String titulo,
    required String cuerpo,
    String? payload,
    String? groupKey, // Nuevo parámetro para agrupar
  }) async {
    await inicializar();

    final androidDetails = AndroidNotificationDetails(
      'arrendaoco_high_importance', // Canal ID
      'Notificaciones Prioritarias', // Canal Nombre
      channelDescription: 'Alertas que despiertan la pantalla',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      groupKey: groupKey, // USAR EL ID DEL USUARIO PARA AGRUPAR
      setAsGroupSummary: false, // Esta es una notificación individual
    );

    const iosDetails = DarwinNotificationDetails(
      threadIdentifier: 'arrendaoco_messages', // Agrupar también en iOS
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generar un ID único de 32 bits para que NO se sobrescriban (y se puedan agrupar)
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _notifications.show(
      notificationId,
      titulo,
      cuerpo,
      details,
      payload: payload,
    );

    // Si hay un groupKey, mandamos también una notificación de resumen (obligatorio en Android para que funcione el grupo)
    if (groupKey != null) {
      final summaryDetails = AndroidNotificationDetails(
        'arrendaoco_high_importance',
        'Notificaciones Prioritarias',
        groupKey: groupKey,
        setAsGroupSummary: true, // ESTA MARCA EL GRUPO
        importance: Importance.max,
        priority: Priority.max,
      );
      
      await _notifications.show(
        groupKey.hashCode, // El ID del resumen debe ser constante por grupo
        'Mensajes nuevos',
        'Tienes varios mensajes',
        NotificationDetails(android: summaryDetails),
      );
    }
  }

  /// Notificar nueva renta creada
  static Future<void> notificarNuevaRenta({
    required String inquilinoId,
    required String inmuebleTitulo,
    required double monto,
  }) async {
    // Guardar en Supabase para que llegue al inquilino
    // Asumimos que inquilinoId es parseable a int
    await BaseDatos.crearNotificacion(
      usuarioId: int.tryParse(inquilinoId) ?? 0,
      titulo: 'Nueva Renta',
      mensaje: 'Has sido vinculado a: $inmuebleTitulo (\$$monto/mes)',
      tipo: 'renta',
    );
  }

  /// Notificar pago próximo
  static Future<void> notificarPagoProximo({
    required String usuarioId,
    required String inmuebleTitulo,
    required int dias,
    required double monto,
  }) async {
    await BaseDatos.crearNotificacion(
      usuarioId: int.tryParse(usuarioId) ?? 0,
      titulo: 'Pago Próximo',
      mensaje: 'El pago de $inmuebleTitulo vence en $dias días (\$$monto)',
      tipo: 'pago',
    );
  }

  /// Notificar pago vencido
  static Future<void> notificarPagoVencido({
    required String usuarioId,
    required String inmuebleTitulo,
    required double monto,
  }) async {
    await BaseDatos.crearNotificacion(
      usuarioId: int.tryParse(usuarioId) ?? 0,
      titulo: 'Pago Vencido',
      mensaje: 'El pago de $inmuebleTitulo está vencido (\$$monto)',
      tipo: 'pago',
    );
  }

  /// Notificar nuevo inmueble publicado
  static Future<void> notificarNuevoInmueble({
    required String titulo,
    required double precio,
  }) async {
    await mostrarNotificacion(
      titulo: '🏡 Nuevo Inmueble',
      cuerpo: '$titulo - \$$precio',
    );
  }

  /// Notificar pago confirmado
  static Future<void> notificarPagoConfirmado({
    required String usuarioId,
    required String inmuebleTitulo,
    required String mes,
  }) async {
    await BaseDatos.crearNotificacion(
      usuarioId: int.tryParse(usuarioId) ?? 0,
      titulo: 'Pago Confirmado',
      mensaje: 'El pago de $mes para $inmuebleTitulo ha sido confirmado',
      tipo: 'pago',
    );
  }

  /// Notificar nueva reseña al propietario
  static Future<void> notificarNuevaResena({
    required int propietarioId,
    required int inmuebleId,
    required String nombreInmueble,
    required String autorNombre,
    required String comentario,
    required int resenaId,
  }) async {
    await BaseDatos.crearNotificacion(
      usuarioId: propietarioId,
      titulo: 'Nueva Reseña',
      mensaje: '$autorNombre comentó en $nombreInmueble: "$comentario"',
      tipo: 'resena',
      referenciaId: resenaId, // Deep link a la reseña
    );
  }

  static Future<void> notificarRespuestaResena({
    required int usuarioDestinoId,
    required String nombreInmueble,
    required int resenaId,
    required String mensajeChat, // Agregamos el contenido del mensaje
    String? tituloPersonalizado, // Título opcional ("Mensaje de X")
  }) async {
    await BaseDatos.crearNotificacion(
      usuarioId: usuarioDestinoId,
      titulo: tituloPersonalizado ?? 'Nueva respuesta en reseña',
      mensaje:
          'En $nombreInmueble: "$mensajeChat"', // Mostramos el mensaje real
      tipo: 'resena',
      referenciaId: resenaId,
    );
  }

  static void escucharNotificaciones(int usuarioId) async {
    // TODO: Implementar con Laravel Echo o FCM
    print(
      'ℹ️ Escuchar notificaciones realtime está deshabilitado temporalmente (Sin Supabase)',
    );
  }
}
