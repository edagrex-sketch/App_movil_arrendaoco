import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';

class FCMService {
  // Mantenemos el nombre de la clase para compatibilidad,
  // pero ahora usa Supabase Realtime en lugar de Firebase FCM.

  static RealtimeChannel? _channel;

  /// Inicia la escucha de notificaciones en tiempo real para el usuario actual via Supabase
  static void initialize(int usuarioId) {
    if (_channel != null) {
      return; // Ya está escuchando
    }

    print(
      '🔔 Iniciando escucha de notificaciones Realtime para usuario: $usuarioId',
    );

    _channel = Supabase.instance.client
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
            print('🔔 Recibida notificación Realtime: ${payload.newRecord}');
            final data = payload.newRecord;

            final titulo = data['titulo'] ?? 'Nueva notificación';
            final mensaje = data['mensaje'] ?? 'Tienes un nuevo mensaje';

            // Mostrar notificación local
            NotificacionesService.mostrarNotificacion(
              titulo: titulo,
              cuerpo: mensaje,
            );
          },
        )
        .subscribe();
  }

  /// Detiene la escucha (usar al cerrar sesión)
  static void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      print('🔕 Escucha de notificaciones detenida');
    }
  }
}
