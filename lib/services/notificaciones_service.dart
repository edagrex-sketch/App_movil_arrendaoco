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
      'arrendaoco_channel',
      'ArrendaOco Notificaciones',
      channelDescription: 'Notificaciones de la app ArrendaOco',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
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
    // Guardar en SQLite
    // Asumimos que inquilinoId es parseable a int
    await BaseDatos.crearNotificacion(
      usuarioId: int.tryParse(inquilinoId) ?? 0,
      titulo: 'Nueva Renta',
      mensaje: 'Has sido vinculado a: $inmuebleTitulo (\$$monto/mes)',
      tipo: 'renta',
    );

    // Mostrar notificación push (solo si la app está abierta)
    await mostrarNotificacion(
      titulo: '🏠 Nueva Renta',
      cuerpo: 'Has sido vinculado a: $inmuebleTitulo',
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

    await mostrarNotificacion(
      titulo: '💰 Pago Próximo',
      cuerpo: '$inmuebleTitulo - Vence en $dias días',
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

    await mostrarNotificacion(
      titulo: '🔴 Pago Vencido',
      cuerpo: '$inmuebleTitulo - \$$monto',
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

    await mostrarNotificacion(
      titulo: '✅ Pago Confirmado',
      cuerpo: '$inmuebleTitulo - $mes',
    );
  }
}
