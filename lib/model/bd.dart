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
    // Supabase update no devuelve 'rows affected' como int directamente de la misma forma que sqflite
    // Pero si no falla, asumimos éxito. Retornamos ID por convención.
    await _supabase.from('inmuebles').update(data).eq('id', id);
    return id;
  }

  static Future<int> eliminarInmueble(int id) async {
    await _supabase.from('inmuebles').delete().eq('id', id);
    return id; // Retornamos ID eliminado
  }

  // ================== RESEÑAS ==================

  static Future<int> insertarResena(Map<String, dynamic> resena) async {
    // En Supabase 'rating' es integer, asegurarse que se envíe bien
    final response = await _supabase
        .from('resenas')
        .insert(resena)
        .select('id')
        .single();
    return response['id'] as int;
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
    // Supabase no tiene agregation queries directas simples en el cliente Dart sin usar RPC.
    // Lo haremos en cliente por ahora (no es ideal para millones de filas, pero ok por ahora)
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
    // Join manual: Obtener favoritos y luego inmuebles, o usar select relacional
    // Usaremos select relacional: inmuebles!inner(...)
    // Ojo: La tabla favoritos tiene inmueble_id.
    // Query: Select all favorites for user, expand inmueble data.

    final response = await _supabase
        .from('favoritos')
        .select('*, inmuebles(*)')
        .eq('usuario_id', usuarioId)
        .order('fecha_agregado', ascending: false);

    // Mapear resultado para que parezca una lista de inmuebles plana, como espera la UI
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
    // Necesitamos datos de inquilino e inmueble
    // Relaciones: rentas -> inmuebles, rentas -> usuarios (inquilino_id)
    // Ojo: inquilino_id es FK a usuarios. Supabase detecta FKs. as 'inquilino' si configuramos el nombre o usamos la tabla directamente.
    // Como tenemos multiples FK a usuarios (arrendador, inquilino), necesitamos especificar cual.
    // Sintaxis: usuarios!inquilino_id(...)

    final response = await _supabase
        .from('rentas')
        .select('*, inmuebles(*), inquilino:usuarios!inquilino_id(*)')
        .eq('arrendador_id', arrendadorId)
        .order('fecha_inicio', ascending: false);

    // Aplanar para compatibilidad
    return List<Map<String, dynamic>>.from(
      response.map((r) {
        final inmueble = r['inmuebles'] as Map<String, dynamic>;
        final inquilino = r['inquilino'] as Map<String, dynamic>;

        final newMap = Map<String, dynamic>.from(r);
        newMap['inmueble_titulo'] = inmueble['titulo'];
        newMap['rutas_imagen'] = inmueble['rutas_imagen'];
        newMap['inquilino_nombre'] = inquilino['nombre'];

        // Limpiar objetos anidados si queremos o dejarlos
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

  static Future<Map<String, dynamic>?> obtenerRentaPorId(int rentaId) async {
    final response = await _supabase
        .from('rentas')
        .select(
          '*, inmuebles(*), inquilino:usuarios!inquilino_id(*), arrendador:usuarios!arrendador_id(*)',
        )
        .eq('id', rentaId)
        .maybeSingle();

    if (response == null) return null;

    final inmueble = response['inmuebles'] as Map<String, dynamic>;
    final inquilino = response['inquilino'] as Map<String, dynamic>;
    final arrendador = response['arrendador'] as Map<String, dynamic>;

    final newMap = Map<String, dynamic>.from(response);
    newMap['inmueble_titulo'] = inmueble['titulo'];
    newMap['rutas_imagen'] = inmueble['rutas_imagen'];
    newMap['inquilino_nombre'] = inquilino['nombre'];
    newMap['inquilino_id'] = inquilino['id'];
    newMap['arrendador_nombre'] = arrendador['nombre'];
    newMap['arrendador_id'] = arrendador['id'];

    return newMap;
  }

  static Future<bool> verificarInquilinoExiste(int inquilinoId) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('id', inquilinoId)
        .eq('rol', 'Inquilino')
        .maybeSingle();
    return response != null;
  }

  static Future<bool> inmuebleTieneRentaActiva(int inmuebleId) async {
    final response = await _supabase
        .from('rentas')
        .select()
        .eq('inmueble_id', inmuebleId)
        .eq('estado', 'activa')
        .maybeSingle();
    return response != null;
  }

  static Future<int> actualizarEstadoRenta(int rentaId, String estado) async {
    await _supabase.from('rentas').update({'estado': estado}).eq('id', rentaId);
    return rentaId;
  }

  // ================== PAGOS DE RENTA ==================

  static Future<int> registrarPago(Map<String, dynamic> pago) async {
    final response = await _supabase
        .from('pagos_renta')
        .insert(pago)
        .select('id')
        .single();
    return response['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> obtenerPagosPorRenta(
    int rentaId,
  ) async {
    final response = await _supabase
        .from('pagos_renta')
        .select()
        .eq('renta_id', rentaId)
        .order('anio', ascending: true)
        .order(
          'mes',
          ascending: true,
        ); // Mes es texto... esto podría ordenar alfabéticamente mal si no usamos nº. Pero seguimos lógica previa.
    // Lo ideal sería tener un campo mes_numero, pero seguimos backward compat.

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<int> actualizarEstadoPago(
    int pagoId,
    String estado,
    String? fechaPago,
  ) async {
    final data = {'estado': estado};
    if (fechaPago != null) {
      data['fecha_pago'] = fechaPago;
    }
    await _supabase.from('pagos_renta').update(data).eq('id', pagoId);
    return pagoId;
  }

  static Future<Map<String, dynamic>?> obtenerProximoPago(int rentaId) async {
    // orderBy fecha_vencimiento
    final response = await _supabase
        .from('pagos_renta')
        .select()
        .eq('renta_id', rentaId)
        .eq('estado', 'pendiente')
        .order('fecha_vencimiento', ascending: true)
        .limit(1)
        .maybeSingle();
    return response;
  }

  static Future<void> generarPagosMensuales(
    int rentaId,
    DateTime fechaInicio,
    double monto,
    int diaPago,
    int meses,
  ) async {
    final List<Map<String, dynamic>> pagos = [];

    for (int i = 0; i < meses; i++) {
      final fecha = DateTime(fechaInicio.year, fechaInicio.month + i, diaPago);
      final mes = _getNombreMes(fecha.month);
      final anio = fecha.year;

      pagos.add({
        'renta_id': rentaId,
        'mes': mes,
        'anio': anio,
        'monto': monto,
        'fecha_vencimiento': fecha.toIso8601String(),
        'estado': 'pendiente',
      });
    }

    // Batch insert
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

  // ================== NOTIFICACIONES ==================

  static Future<int> crearNotificacion({
    required int usuarioId,
    required String titulo,
    required String mensaje,
    String tipo = 'sistema',
  }) async {
    final response = await _supabase
        .from('notificaciones')
        .insert({
          'usuario_id': usuarioId,
          'titulo': titulo,
          'mensaje': mensaje,
          'tipo': tipo,
          'leida': 0,
          'fecha': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return response['id'] as int;
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
