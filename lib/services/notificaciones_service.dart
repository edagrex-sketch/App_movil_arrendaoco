import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/main.dart';
import 'package:arrendaoco/view/chats/chat_screen.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/view/mis_rentas.dart';
import 'package:arrendaoco/view/gestionar_rentas.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;
  
  // Stream para avisar a la UI cuando llega una nueva notificación
  static final StreamController<void> _onNotificationReceivedController = StreamController<void>.broadcast();
  static Stream<void> get onNotificationReceived => _onNotificationReceivedController.stream;

  static void refrescarBadge() {
    _onNotificationReceivedController.add(null);
  }

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
        if (response.payload != null) {
          _manejarRedireccion(response.payload!);
        }
      },
    );

    // Solicitar permisos específicamente para Android 13+
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
        
    await androidPlugin?.requestNotificationsPermission();

    // CREAR CANAL DE ALTA IMPORTANCIA EXPLÍCITAMENTE (Para tiempo real en Android 13+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'arrendaoco_high_importance', // id
      'Notificaciones Prioritarias', // title
      description: 'Alertas que despiertan la pantalla', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(channel);

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
      print('📩 Mensaje en primer plano: ${message.messageId}');
      
      // Intentar obtener info del cuerpo ya sea de 'notification' o de 'data'
      final String titulo = message.notification?.title ?? message.data['titulo'] ?? 'Nueva Notificación';
      final String cuerpo = message.notification?.body ?? message.data['mensaje'] ?? '';

      // Mejor extracción de groupKey para agrupar mensajes de la misma persona/chat
      final String? chatRefId = message.data['chat_id']?.toString() ?? 
                               (message.data['tipo'] == 'mensaje' ? message.data['referencia_id']?.toString() : null);

      mostrarNotificacion(
        titulo: titulo,
        cuerpo: cuerpo,
        payload: jsonEncode(message.data),
        groupKey: chatRefId != null ? 'chat_$chatRefId' : null,
      );
      
      // Incluso si no mostramos notificación visual, refrescamos el badge
      refrescarBadge();
    });

    // 4. Listener cuando se abre la App desde una notificación (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🖱️ App abierta desde notificación FCM: ${message.data}');
      _manejarRedireccion(jsonEncode(message.data));
    });

    // 5. Verificar si la app se abrió desde una notificación estando terminada
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _manejarRedireccion(jsonEncode(initialMessage.data));
    }
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
    String? groupKey,
  }) async {
    await inicializar();

    final String? senderName = payload != null ? jsonDecode(payload)['sender_nombre']?.toString() : null;
    final bool esMensaje = groupKey != null && groupKey.startsWith('chat_');

    final androidDetails = AndroidNotificationDetails(
      'arrendaoco_high_importance',
      'Notificaciones Prioritarias',
      channelDescription: 'Alertas que despiertan la pantalla',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      groupKey: groupKey,
      setAsGroupSummary: false,
      tag: groupKey, // Forzar colapso por tag también
      styleInformation: esMensaje 
        ? MessagingStyleInformation(
            Person(
              name: 'Yo',
              key: 'me',
            ),
            conversationTitle: titulo,
            messages: [
              Message(
                cuerpo,
                DateTime.now(),
                Person(name: senderName ?? 'Usuario', key: senderName ?? 'u'),
              ),
            ],
          )
        : null,
    );

    const iosDetails = DarwinNotificationDetails(
      threadIdentifier: 'arrendaoco_messages',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ID único para la notificación individual (usamos el ID de la BD si existe)
    int notificationId;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        // Para mensajes, usaremos un ID fijo por chat para que se APILEN en la misma tarjeta
        if (esMensaje) {
          notificationId = groupKey.hashCode;
        } else {
          notificationId = int.tryParse(data['id']?.toString() ?? '') ?? 
                           DateTime.now().millisecondsSinceEpoch % 2147483647;
        }
      } catch (_) {
        notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      }
    } else {
      notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
    }

    await _notifications.show(
      notificationId,
      titulo,
      cuerpo,
      details,
      payload: payload,
    );

    // NOTIFICAR A LA UI PARA ACTUALIZAR EL BADGE EN TIEMPO REAL
    _onNotificationReceivedController.add(null);

    if (groupKey != null) {
      final summaryDetails = AndroidNotificationDetails(
        'arrendaoco_high_importance',
        'Notificaciones Prioritarias',
        groupKey: groupKey,
        setAsGroupSummary: true,
        importance: Importance.max,
        priority: Priority.max,
        styleInformation: InboxStyleInformation(
          [],
          contentTitle: esMensaje ? 'Conversación con $senderName' : titulo,
          summaryText: 'Nuevos mensajes',
        ),
      );
      
      // El ID del resumen debe ser ÚNICO del grupo pero DIFERENTE a las individuales
      await _notifications.show(
        groupKey.hashCode + 999, // Offset para no chocar con IDs individuales
        'Nuevos mensajes',
        'Tienes varios mensajes pendientes',
        NotificationDetails(android: summaryDetails),
      );
    }
  }

  /// LÓGICA DE DEEP LINKING / REDIRECCIÓN
  static void _manejarRedireccion(String payloadRaw) async {
    try {
      final data = jsonDecode(payloadRaw);
      final String? tipo = data['tipo']?.toString() ?? data['type']?.toString();
      final String? idStr = data['id']?.toString() ?? data['referencia_id']?.toString();

      final nav = MyApp.navigatorKey.currentState;
      if (nav == null) {
        print('❌ No se pudo obtener el NavigatorState');
        return;
      }

      print('🚀 Redirigiendo por notificación: tipo=$tipo, id=$idStr');

      // MARCAR COMO LEÍDA EN EL SERVIDOR SI TENEMOS EL ID
      final notifId = data['id']?.toString() ?? data['notificacion_id']?.toString();
      if (notifId != null) {
        _marcarComoLeida(notifId);
      }

      switch (tipo) {
        case 'mensaje':
          final chatId = int.tryParse(data['chat_id']?.toString() ?? idStr ?? '');
          if (chatId != null) {
            // Necesitamos los datos del otro usuario. Si no vienen, intentamos traerlos o ir a la lista.
            final otroUsuario = {
              'id': data['sender_id'],
              'nombre': data['sender_nombre'] ?? 'Usuario',
              'foto_perfil': data['sender_foto'],
            };
            nav.push(MaterialPageRoute(builder: (context) => ChatScreen(
              chatId: chatId,
              otroUsuario: otroUsuario,
            )));
          }
          break;

        case 'renta':
        case 'solicitud':
        case 'contrato':
          // Ir a Mis Rentas o al detalle del inmueble
          nav.push(MaterialPageRoute(builder: (context) => const MisRentasScreen()));
          break;

        case 'inmueble':
          final inmuebleId = int.tryParse(idStr ?? '');
          if (inmuebleId != null) {
             // Mockup del objeto inmueble mínimo para el Detalle
            nav.push(MaterialPageRoute(builder: (context) => DetalleInmuebleScreen(
              inmueble: {'id': inmuebleId, 'titulo': data['inmueble_titulo'] ?? 'Propiedad'},
            )));
          }
          break;

        case 'pago':
          // Si es Propietario, ir a Gestión. Si es Inquilino, ir a Mis Rentas.
          // Como no sabemos el rol aquí fácilmente, podemos ir a Mis Rentas que es común.
          nav.push(MaterialPageRoute(builder: (context) => const MisRentasScreen()));
          break;
        
        default:
          print('ℹ️ Tipo de notificación desconocido para redirección: $tipo');
          break;
      }
    } catch (e) {
      print('❌ Error en _manejarRedireccion: $e');
    }
  }

  static void _marcarComoLeida(String id) async {
    try {
      final api = ApiService();
      await api.put('/notificaciones/$id');
      print('✅ Notificación $id marcada como leída');
      
      // Actualizar el badge en tiempo real
      _onNotificationReceivedController.add(null);
    } catch (e) {
      print('❌ Error al marcar como leída: $e');
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
