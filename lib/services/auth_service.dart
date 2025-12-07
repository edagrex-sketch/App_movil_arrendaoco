import 'package:supabase_flutter/supabase_flutter.dart';

class LocalUser {
  final String uid;
  LocalUser({required this.uid});
}

class AuthService {
  final _supabase = Supabase.instance.client;

  AuthService();

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Login simple contra tabla usuarios
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('username', email)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        final userRow = response;
        return {
          'success': true,
          'user': LocalUser(uid: userRow['id'].toString()),
          'userData': {
            'nombre': userRow['nombre'],
            'email': userRow['username'],
            'rol': userRow['rol'],
            'public_id': (userRow['id'] as int).toString(),
          },
        };
      } else {
        return {'success': false, 'message': 'Credenciales incorrectas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      // Verificar si ya existe
      final exists = await _supabase
          .from('usuarios')
          .select()
          .eq('username', email)
          .maybeSingle();

      if (exists != null) {
        return {'success': false, 'message': 'El usuario ya existe'};
      }

      // Insertar nuevo usuario
      // Supabase insert devuelve un array, seleccionamo single
      final response = await _supabase
          .from('usuarios')
          .insert({
            'username': email,
            'password': password,
            'nombre': nombre,
            'rol': rol,
          })
          .select('id')
          .single();

      final id = response['id'] as int;

      return {
        'success': true,
        'user': LocalUser(uid: id.toString()),
        'userData': {
          'nombre': nombre,
          'email': email,
          'rol': rol,
          'public_id': id.toString(),
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al registrar: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    return {
      'success': true,
      'message': 'Funcionalidad no disponible en backend simplificado.',
    };
  }

  LocalUser? get currentUser {
    // No manejamos sesión persistente en este servicio, se maneja en UI con SesionActual
    return null;
  }

  Future<void> signOut() async {
    // Nada que cerrar, sesión es local en RAM
    return;
  }
}
