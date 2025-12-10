import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  static RealtimeChannel? _activeChannel;

  static void escucharNotificaciones(int usuarioId) async {
    // 1. Limpiar suscripción anterior si existe para evitar duplicados
    if (_activeChannel != null) {
      await Supabase.instance.client.removeChannel(_activeChannel!);
      _activeChannel = null;
    }

    print('🔔 Iniciando suscripción limpia para usuario: $usuarioId');

    // 2. Crear nueva suscripción
    _activeChannel = Supabase.instance.client.channel(
      'public:notificaciones:$usuarioId',
    );

    _activeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificaciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column:
                'usuario_id', // Escuchamos donde el usuario es el DESTINATARIO
            value: usuarioId,
          ),
          callback: (payload) async {
            print('🔔 ¡Notificación REALTIME recibida!');
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              // Extraer datos
              final titulo = newRecord['titulo'] ?? 'Nueva Notificación';
              final mensaje = newRecord['mensaje'] ?? 'Tienes un nuevo mensaje';

              // Mostrar notificación local
              await mostrarNotificacion(
                titulo: titulo,
                cuerpo: mensaje,
                // Podemos pasar data extra en el payload si queremos deep link luego
              );
            }
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Conexión establecida a notificaciones');
          } else if (status == RealtimeSubscribeStatus.closed) {
            print('❌ Conexión cerrada');
          } else if (error != null) {
            print('⚠️ Error en suscripción: $error');
          }
        });
  }
}
