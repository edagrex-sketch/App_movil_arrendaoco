import 'package:flutter/foundation.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:dio/dio.dart';

class BaseDatos {
  static final _api = ApiService();

  // ================== USUARIOS ==================

  static Future<Map<String, dynamic>?> obtenerUsuario(int id) async {
    try {
      final response = await _api.get('/me');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  static Future<void> actualizarUsuario(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _api.post('/perfil/actualizar', data: data);
    } catch (e) {
      debugPrint('Error actualizando usuario: $e');
    }
  }

  // ================== INMUEBLES ==================

  static Future<int> insertarInmueble(
    Map<String, dynamic> data, [
    List<String>? imagePaths,
  ]) async {
    try {
      final formData = FormData.fromMap({
        ...data,
        if (imagePaths != null && imagePaths.isNotEmpty)
          'imagenes[]': await Future.wait(
            imagePaths.map((path) => MultipartFile.fromFile(path)),
          ),
      });

      final response = await _api.post('/inmuebles', data: formData);
      return response.data['data']['id'] ?? 0;
    } catch (e) {
      debugPrint('Error insertando inmueble: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerInmuebles() async {
    try {
      final response = await _api.get('/inmuebles/public-list');
      final List data = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerInmueblesPorPropietario(
    int propietarioId,
  ) async {
    try {
      final response = await _api.get('/inmuebles');
      final List data = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<int> actualizarInmueble(
    int id,
    Map<String, dynamic> data, [
    List<String>? newImagePaths,
  ]) async {
    try {
      final formData = FormData.fromMap({
        ...data,
        '_method': 'PUT', // Simular PUT en un POST para FormData
        if (newImagePaths != null && newImagePaths.isNotEmpty)
          'imagenes[]': await Future.wait(
            newImagePaths.map((path) => MultipartFile.fromFile(path)),
          ),
      });

      await _api.post('/inmuebles/$id', data: formData);
      return id;
    } catch (e) {
      debugPrint('Error actualizando inmueble: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>?> obtenerInmueblePorId(int id) async {
    try {
      final response = await _api.get('/inmuebles/public-detail/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error obteniendo inmueble por id: $e');
      return null;
    }
  }

  static Future<int> eliminarInmueble(int id) async {
    try {
      await _api.delete('/inmuebles/$id');
      return id;
    } catch (e) {
      return 0;
    }
  }

  // ================== RESEÑAS (SYNC CON LARAVEL) ==================

  static Future<int> insertarResena(Map<String, dynamic> resena) async {
    try {
      final response = await _api.post(
        '/inmuebles/${resena['inmueble_id']}/resenas',
        data: {
          'puntuacion': resena['rating'],
          'comentario': resena['comentario'],
        },
      );
      return (response.data['resena'] != null)
          ? (response.data['resena']['id'] ?? 0)
          : 0;
    } catch (e) {
      debugPrint('Error insertando reseña: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerResenasPorInmueble(
    int inmuebleId,
  ) async {
    try {
      final response = await _api.get('/inmuebles/$inmuebleId/resenas');
      final List data = (response.data is Map)
          ? (response.data['data'] ?? [])
          : [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> eliminarResena(int id) async {
    try {
      await _api.delete('/resenas/$id');
    } catch (e) {
      debugPrint('Error eliminando reseña: $e');
    }
  }

  static Future<Map<String, dynamic>?> obtenerResenaPorId(int id) async {
    try {
      final response = await _api.get('/resenas/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error obteniendo reseña por id: $e');
      return null;
    }
  }

  // ================== CHAT (AI / ARRENDITO) ==================

  static Future<String> enviarMensajeChat(String mensaje) async {
    try {
      final response = await _api.post(
        '/arrendito/chat',
        data: {'message': mensaje},
      );
      return response.data['reply'] ??
          'Lo siento, no pude procesar tu mensaje.';
    } catch (e) {
      return 'Error de conexión con Roco.';
    }
  }

  // ================== FAVORITOS (SYNC CON LARAVEL) ==================

  static Future<void> agregarFavorito(int usuarioId, int inmuebleId) async {
    try {
      await _api.post('/favoritos/$inmuebleId/toggle');
    } catch (e) {
      debugPrint('Error agregando favorito: $e');
    }
  }

  static Future<void> eliminarFavorito(int usuarioId, int inmuebleId) async {
    try {
      await _api.post('/favoritos/$inmuebleId/toggle');
    } catch (e) {
      debugPrint('Error eliminando favorito: $e');
    }
  }

  static Future<bool> esFavorito(int usuarioId, int inmuebleId) async {
    try {
      final response = await _api.get('/favoritos');
      final List data = (response.data is Map)
          ? (response.data['data'] ?? [])
          : [];
      return data.any((i) => i['id'] == inmuebleId);
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerFavoritos(
    int usuarioId,
  ) async {
    try {
      final response = await _api.get('/favoritos');
      final List data = (response.data is Map)
          ? (response.data['data'] ?? [])
          : [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ================== CALENDARIO ==================

  static Future<int> agregarEvento(Map<String, dynamic> evento) async {
    try {
      final response = await _api.post('/calendario', data: evento);
      return response.data['id'] ?? 0;
    } catch (e) {
      debugPrint('Error agregando evento: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerEventosPorUsuario(
    int usuarioId,
  ) async {
    try {
      final response = await _api.get('/calendario');
      final List data = response.data;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<int> eliminarEvento(int eventoId) async {
    try {
      await _api.delete('/calendario/$eventoId');
      return eventoId;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerEventosPorRenta(
    int rentaId,
  ) async {
    try {
      final response = await _api.get('/contratos/$rentaId/eventos');
      final List data = response.data;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ================== RENTAS ==================

  static Future<int> crearRenta(Map<String, dynamic> renta) async {
    try {
      final inmuebleId = renta['inmueble_id'];
      final response = await _api.post(
        '/inmuebles/$inmuebleId/rentar',
        data: {
          'inquilino_id': renta['inquilino_id'],
          'fecha_inicio': renta['fecha_inicio'],
          'fecha_fin': renta['fecha_fin'],
          'renta_mensual': renta['monto_mensual'],
          'deposito': renta['deposito'],
        },
      );
      return response.data['id'] ?? 0;
    } catch (e) {
      debugPrint('Error creando renta: $e');
      return 0;
    }
  }

  static Future<void> actualizarEstadoRenta(int id, String estado) async {
    try {
      // Laravel uses renover/cancelar or we can add a generic one.
      // For now, let's assume we might need a generic update or specific actions.
      if (estado == 'cancelada') {
        await _api.post('/contratos/$id/cancelar');
      }
    } catch (e) {
      debugPrint('Error actualizando estado renta: $e');
    }
  }

  static Future<void> eliminarTodasLasRentas(int usuarioId) async {
    // This is destructive and not directly exposed in the API as a bulk operation.
    // For now, we'll leave it empty or implement it if critical for testing.
  }

  static Future<List<Map<String, dynamic>>> obtenerRentasPorArrendador(
    int arrendadorId,
  ) async {
    try {
      final response = await _api.get('/contratos');
      final List data = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(
        data,
      ).where((r) => r['arrendador_id'] == arrendadorId).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerRentasPorInquilino(
    int inquilinoId,
  ) async {
    try {
      final response = await _api.get('/contratos');
      final List data = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(
        data,
      ).where((r) => r['inquilino_id'] == inquilinoId).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> obtenerRentaPorId(int id) async {
    try {
      // This is a bit tricky as we don't have a direct /contratos/{id} that returns this specific format
      // But we can filter the index or add a show method to ContratoController
      final response = await _api.get('/contratos');
      final List data = response.data['data'] ?? [];
      final match = data.firstWhere((r) => r['id'] == id, orElse: () => null);
      return match;
    } catch (e) {
      return null;
    }
  }

  static Future<int> verificarInquilinoExiste(String email) async {
    // Instead of querying Supabase, we could add a verify-user endpoint.
    // However, if we only need this for the rental form, we can just assume
    // the user exists or let the API error handle it.
    // For now, let's fetch all users from public list or common endpoint if exists.
    // Or just trust the API.
    return 0; // Temporary
  }

  // ================== PAGOS ==================

  static Future<void> generarPagosMensuales(
    int rentaId,
    DateTime fechaInicio,
    int duracionMeses,
    double monto,
  ) async {
    try {
      await _api.post(
        '/contratos/$rentaId/pagos/generar',
        data: {'meses': duracionMeses},
      );
    } catch (e) {
      debugPrint('Error generando pagos: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerPagosDeRenta(
    int rentaId,
  ) async {
    try {
      final response = await _api.get('/contratos/$rentaId/estado-cuenta');
      final List data = response.data['pagos'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> actualizarEstadoPago(
    int pagoId,
    String nuevoEstado, [
    String? fechaReal,
  ]) async {
    try {
      if (nuevoEstado == 'pagado') {
        await _api.post('/pagos/$pagoId/pagar');
      }
    } catch (e) {
      debugPrint('Error actualizando estado pago: $e');
    }
  }

  // ================== NOTIFICACIONES ==================

  static Future<int> crearNotificacion({
    required int usuarioId,
    required String titulo,
    required String mensaje,
    String tipo = 'sistema',
    int? referenciaId,
  }) async {
    // Usually notifications are created server-side in Laravel,
    // but if we need to create one from the App (e.g. peer-to-peer feedback):
    try {
      final response = await _api.post(
        '/notificaciones',
        data: {
          'usuario_id': usuarioId,
          'titulo': titulo,
          'mensaje': mensaje,
          'tipo': tipo,
          'referencia_id': referenciaId,
        },
      );
      return response.data['id'] ?? 0;
    } catch (e) {
      debugPrint('Error creando notificación: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerNotificaciones(
    int usuarioId,
  ) async {
    try {
      final response = await _api.get('/notificaciones');
      final List data = response.data;
      return List<Map<String, dynamic>>.from(data).map((n) {
        // Normalize date field if necessary (Laravel uses created_at)
        final Map<String, dynamic> map = Map<String, dynamic>.from(n);
        map['fecha'] = n['created_at'];
        return map;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> marcarComoLeida(int notificacionId) async {
    try {
      await _api.put('/notificaciones/$notificacionId', data: {'leida': true});
      return notificacionId;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> contarNoLeidas(int usuarioId) async {
    try {
      final response = await _api.get('/notificaciones/unread-count');
      return response.data['unread_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> eliminarNotificacion(int notificacionId) async {
    try {
      await _api.delete('/notificaciones/$notificacionId');
      return notificacionId;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> marcarTodasComoLeidas(int usuarioId) async {
    try {
      await _api.post('/notificaciones/mark-all-read');
      return 1;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerPagosPendientes(
    int usuarioId,
    String rol,
  ) async {
    try {
      final response = await _api.get('/pagos/pendientes');
      final List data = response.data;
      return List<Map<String, dynamic>>.from(
        data.map((p) {
          return {
            'id': -1 * (p['id'] as int),
            'titulo': 'Próximo Pago',
            'descripcion': '\$${p['monto']} - ${p['inmueble_titulo']}',
            'fecha': p['fecha_pago'],
            'tipo': 'pago',
            'original_id': p['id'],
          };
        }),
      );
    } catch (e) {
      return [];
    }
  }
}
