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

  /// Mostrar notificación inmediata
  static Future<void> mostrarNotificacion({
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    await inicializar();

    const androidDetails = AndroidNotificationDetails(
      'arrendaoco_high_importance', // Canal ID
      'Notificaciones Prioritarias', // Canal Nombre
      channelDescription: 'Alertas que despiertan la pantalla',
      importance: Importance.max, // Máxima importancia para despertar
      priority: Priority.max, // Máxima prioridad
      showWhen: true,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // CLAVE PARA DESPERTAR (si tiene permiso)
      category:
          AndroidNotificationCategory.call, // Simular llamada ayuda a despertar
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generar un ID único de 32 bits para que NO se sobrescriban
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _notifications.show(
      notificationId,
      titulo,
      cuerpo,
      details,
      payload: payload,
    );
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
