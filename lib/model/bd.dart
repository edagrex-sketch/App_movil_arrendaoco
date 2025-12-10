import 'package:supabase_flutter/supabase_flutter.dart';

class BaseDatos {
  static final _supabase = Supabase.instance.client;

  // ================== USUARIOS ==================

  static Future<Map<String, dynamic>?> obtenerUsuario(int id) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  static Future<void> actualizarUsuario(
    int id,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('usuarios').update(data).eq('id', id);
  }

  // ================== INMUEBLES ==================

  static Future<int> insertarInmueble(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('inmuebles')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> obtenerInmuebles() async {
    final response = await _supabase
        .from('inmuebles')
        .select()
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> obtenerInmueblesPorPropietario(
    int propietarioId,
  ) async {
    final response = await _supabase
        .from('inmuebles')
        .select()
        .eq('propietario_id', propietarioId)
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<int> actualizarInmueble(
    int id,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('inmuebles').update(data).eq('id', id);
    return id;
  }

  static Future<Map<String, dynamic>?> obtenerInmueblePorId(int id) async {
    final response = await _supabase
        .from('inmuebles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  static Future<int> eliminarInmueble(int id) async {
    await _supabase.from('favoritos').delete().eq('inmueble_id', id);
    await _supabase.from('resenas').delete().eq('inmueble_id', id);

    final rentas = await _supabase
        .from('rentas')
        .select('id')
        .eq('inmueble_id', id);
    for (var r in rentas) {
      final rId = r['id'];
      await _supabase.from('pagos_renta').delete().eq('renta_id', rId);
      await _supabase.from('calendario').delete().eq('renta_id', rId);
    }
    await _supabase.from('rentas').delete().eq('inmueble_id', id);
    await _supabase.from('inmuebles').delete().eq('id', id);
    return id;
  }

  // ================== RESEÑAS ==================

  /// Inserta una reseña y devuelve su ID.
  static Future<int> insertarResena(Map<String, dynamic> resena) async {
    try {
      final response = await _supabase
          .from('resenas')
          .insert(resena)
          .select('id')
          .single();
      return response['id'] as int;
    } on PostgrestException catch (e) {
      if (resena.containsKey('usuario_id')) {
        print(
          '⚠️ Error insertando reseña: ${e.message}. Reintentando sin usuario_id.',
        );
        final copia = Map<String, dynamic>.from(resena);
        copia.remove('usuario_id');
        final response = await _supabase
            .from('resenas')
            .insert(copia)
            .select('id')
            .single();
        return response['id'] as int;
      }
      rethrow;
    }
  }

  /// Obtiene una reseña específica por su ID.
  static Future<Map<String, dynamic>?> obtenerResenaPorId(int id) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error buscando reseña $id: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerResenasPorInmueble(
    int inmuebleId,
  ) async {
    final response = await _supabase
        .from('resenas')
        .select()
        .eq('inmueble_id', inmuebleId)
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> obtenerResumenResenas(
    int inmuebleId,
  ) async {
    final response = await _supabase
        .from('resenas')
        .select('rating')
        .eq('inmueble_id', inmuebleId);

    final list = List<Map<String, dynamic>>.from(response);
    if (list.isEmpty) return {'promedio': 0.0, 'total': 0};

    final total = list.length;
    final sum = list.fold<num>(0, (prev, e) => prev + (e['rating'] as num));
    final promedio = sum / total;

    return {'promedio': promedio.toDouble(), 'total': total};
  }

  static Future<void> actualizarResena(
    int id,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('resenas').update(data).eq('id', id);
  }

  static Future<void> eliminarResena(int id) async {
    await _supabase.from('resenas').delete().eq('id', id);
  }

  static Future<void> responderResena(int id, String respuesta) async {
    await _supabase
        .from('resenas')
        .update({
          'respuesta': respuesta,
          'fecha_respuesta': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // ================== CHAT EN RESEÑAS ==================

  static Stream<List<Map<String, dynamic>>> obtenerMensajesResena(
    int resenaId,
  ) {
    return _supabase
        .from('mensajes_resena')
        .stream(primaryKey: ['id'])
        .eq('resena_id', resenaId)
        .order('fecha', ascending: true);
  }

  static Future<void> enviarMensajeResena({
    required int resenaId,
    required int usuarioId,
    required String usuarioNombre,
    required String mensaje,
  }) async {
    await _supabase.from('mensajes_resena').insert({
      'resena_id': resenaId,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'mensaje': mensaje,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  // ================== FAVORITOS ==================

  static Future<int> agregarFavorito(int usuarioId, int inmuebleId) async {
    final response = await _supabase
        .from('favoritos')
        .insert({
          'usuario_id': usuarioId,
          'inmueble_id': inmuebleId,
          'fecha_agregado': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return response['id'] as int;
  }

  static Future<int> eliminarFavorito(int usuarioId, int inmuebleId) async {
    await _supabase.from('favoritos').delete().match({
      'usuario_id': usuarioId,
      'inmueble_id': inmuebleId,
    });
    return 1;
  }

  static Future<bool> esFavorito(int usuarioId, int inmuebleId) async {
    final response = await _supabase.from('favoritos').select().match({
      'usuario_id': usuarioId,
      'inmueble_id': inmuebleId,
    });
    return (response as List).isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> obtenerFavoritos(
    int usuarioId,
  ) async {
    final response = await _supabase
        .from('favoritos')
        .select('*, inmuebles(*)')
        .eq('usuario_id', usuarioId)
        .order('fecha_agregado', ascending: false);

    final List<Map<String, dynamic>> resultados = [];
    for (var item in response) {
      if (item['inmuebles'] != null) {
        resultados.add(item['inmuebles'] as Map<String, dynamic>);
      }
    }
    return resultados;
  }

  // ================== CALENDARIO ==================

  static Future<int> agregarEvento(Map<String, dynamic> evento) async {
    final response = await _supabase
        .from('calendario')
        .insert(evento)
        .select('id')
        .single();
    return response['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> obtenerEventosPorUsuario(
    int usuarioId,
  ) async {
    final response = await _supabase
        .from('calendario')
        .select()
        .eq('usuario_id', usuarioId)
        .order('fecha', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<int> eliminarEvento(int eventoId) async {
    await _supabase.from('calendario').delete().eq('id', eventoId);
    return eventoId;
  }

  static Future<List<Map<String, dynamic>>> obtenerEventosPorRenta(
    int rentaId,
  ) async {
    final response = await _supabase
        .from('calendario')
        .select()
        .eq('renta_id', rentaId)
        .eq('compartido', 1)
        .order('fecha', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ================== RENTAS ==================

  static Future<int> crearRenta(Map<String, dynamic> renta) async {
    final response = await _supabase
        .from('rentas')
        .insert(renta)
        .select('id')
        .single();
    return response['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> obtenerRentasPorArrendador(
    int arrendadorId,
  ) async {
    final response = await _supabase
        .from('rentas')
        .select('*, inmuebles(*), inquilino:usuarios!inquilino_id(*)')
        .eq('arrendador_id', arrendadorId)
        .order('fecha_inicio', ascending: false);

    return List<Map<String, dynamic>>.from(
      response.map((r) {
        final inmueble = r['inmuebles'] as Map<String, dynamic>;
        final inquilino = r['inquilino'] as Map<String, dynamic>;

        final newMap = Map<String, dynamic>.from(r);
        newMap['inmueble_titulo'] = inmueble['titulo'];
        newMap['rutas_imagen'] = inmueble['rutas_imagen'];
        newMap['inquilino_nombre'] = inquilino['nombre'];

        return newMap;
      }),
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerRentasPorInquilino(
    int inquilinoId,
  ) async {
    final response = await _supabase
        .from('rentas')
        .select('*, inmuebles(*), arrendador:usuarios!arrendador_id(*)')
        .eq('inquilino_id', inquilinoId)
        .order('fecha_inicio', ascending: false);

    return List<Map<String, dynamic>>.from(
      response.map((r) {
        final inmueble = r['inmuebles'] as Map<String, dynamic>;
        final arrendador = r['arrendador'] as Map<String, dynamic>;

        final newMap = Map<String, dynamic>.from(r);
        newMap['inmueble_titulo'] = inmueble['titulo'];
        newMap['rutas_imagen'] = inmueble['rutas_imagen'];
        newMap['arrendador_nombre'] = arrendador['nombre'];

        return newMap;
      }),
    );
  }

  static Future<Map<String, dynamic>?> obtenerRentaPorId(int id) async {
    final response = await _supabase
        .from('rentas')
        .select(
          '*, inmuebles(*), arrendador:usuarios!arrendador_id(*), inquilino:usuarios!inquilino_id(*)',
        )
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    final inmueble = response['inmuebles'] as Map<String, dynamic>;
    final arrendador = response['arrendador'] as Map<String, dynamic>;
    final inquilino = response['inquilino'] as Map<String, dynamic>;

    final newMap = Map<String, dynamic>.from(response);
    newMap['inmueble_titulo'] = inmueble['titulo'];
    newMap['rutas_imagen'] = inmueble['rutas_imagen'];
    newMap['arrendador_nombre'] = arrendador['nombre'];
    newMap['inquilino_nombre'] = inquilino['nombre'];

    return newMap;
  }

  static Future<int> verificarInquilinoExiste(String email) async {
    final response = await _supabase
        .from('usuarios')
        .select('id')
        .eq('email', email)
        .eq('rol', 'inquilino')
        .maybeSingle();

    if (response == null) return 0;
    return response['id'] as int;
  }

  // ================== PAGOS ==================

  static Future<void> generarPagosMensuales(
    int rentaId,
    DateTime fechaInicio,
    int duracionMeses,
    double monto,
  ) async {
    List<Map<String, dynamic>> pagos = [];
    for (int i = 0; i < duracionMeses; i++) {
      final fechaPago = DateTime(
        fechaInicio.year,
        fechaInicio.month + i,
        fechaInicio.day,
      );
      pagos.add({
        'renta_id': rentaId,
        'fecha_pago': fechaPago.toIso8601String(),
        'monto': monto,
        'estado': 'pendiente',
        'mes_correspondiente': _getNombreMes(fechaPago.month),
      });
    }
    await _supabase.from('pagos_renta').insert(pagos);
  }

  static String _getNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  static Future<List<Map<String, dynamic>>> obtenerPagosDeRenta(
    int rentaId,
  ) async {
    final response = await _supabase
        .from('pagos_renta')
        .select()
        .eq('renta_id', rentaId)
        .order('fecha_pago', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> actualizarEstadoPago(
    int pagoId,
    String nuevoEstado, [
    String? fechaReal,
  ]) async {
    final Map<String, dynamic> data = {'estado': nuevoEstado};
    // Descomentar si existe columna para guardar fecha real de pago:
    // if (fechaReal != null) data['fecha_pago_real'] = fechaReal;

    await _supabase.from('pagos_renta').update(data).eq('id', pagoId);
  }

  // ================== NOTIFICACIONES ==================

  static Future<int> crearNotificacion({
    required int usuarioId,
    required String titulo,
    required String mensaje,
    String tipo = 'sistema',
    int? referenciaId,
  }) async {
    final data = {
      'usuario_id': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'leida': 0,
      'fecha': DateTime.now().toIso8601String(),
    };
    // No agregamos referencia_id si es null para evitar violaciones de foreign key si es que hay
    if (referenciaId != null) {
      data['referencia_id'] = referenciaId;
    }

    try {
      final response = await _supabase
          .from('notificaciones')
          .insert(data)
          .select('id')
          .single();
      return response['id'] as int;
    } catch (e) {
      // Si falla, intentamos sin referencia_id por si hay un error de schema/FK
      if (referenciaId != null) {
        print(
          '⚠️ Error al crear notificación con ref: $e. Reintentando sin ref.',
        );
        data.remove('referencia_id');
        final response = await _supabase
            .from('notificaciones')
            .insert(data)
            .select('id')
            .single();
        return response['id'] as int;
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerNotificaciones(
    int usuarioId,
  ) async {
    final response = await _supabase
        .from('notificaciones')
        .select()
        .eq('usuario_id', usuarioId)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<int> marcarComoLeida(int notificacionId) async {
    await _supabase
        .from('notificaciones')
        .update({'leida': 1})
        .eq('id', notificacionId);
    return notificacionId;
  }

  static Future<int> contarNoLeidas(int usuarioId) async {
    final count = await _supabase
        .from('notificaciones')
        .count(CountOption.exact)
        .eq('usuario_id', usuarioId)
        .eq('leida', 0);
    return count;
  }

  static Future<int> eliminarNotificacion(int notificacionId) async {
    await _supabase.from('notificaciones').delete().eq('id', notificacionId);
    return notificacionId;
  }

  static Future<int> marcarTodasComoLeidas(int usuarioId) async {
    await _supabase
        .from('notificaciones')
        .update({'leida': 1})
        .eq('usuario_id', usuarioId);
    return 1;
  }
}
