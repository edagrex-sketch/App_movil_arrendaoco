import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/utils/validators.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LocalUser {
  final String uid;
  LocalUser({required this.uid});
}

class AuthService {
  final ApiService _api = ApiService();

  AuthService();

  /// Inicia sesión con Laravel
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final emailLimpio = Validators.sanitizeEmail(email);

      if (!Validators.isValidEmail(emailLimpio)) {
        return {'success': false, 'message': 'Email inválido.'};
      }

      final response = await _api.post(
        '/login',
        data: {'email': emailLimpio, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final userData = data['usuario'];

        // Guardar token para futuras peticiones
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', userData['nombre'] ?? '');

        // Manejo seguro de roles
        final rolesList =
            (data['usuario']['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        String userRole = 'inquilino';
        if (rolesList.isNotEmpty) {
          final lowerRoles = rolesList.map((r) => r.toLowerCase()).toList();
          if (lowerRoles.contains('propietario') ||
              lowerRoles.contains('arrendador') ||
              lowerRoles.contains('admin') ||
              lowerRoles.contains('administrador')) {
            userRole = lowerRoles.firstWhere(
              (r) =>
                  r == 'propietario' ||
                  r == 'arrendador' ||
                  r == 'admin' ||
                  r == 'administrador',
            );
          } else {
            userRole = lowerRoles[0];
          }
        }

        await prefs.setString('user_role', userRole);
        await prefs.setString('user_id', userData['id'].toString());

        return {
          'success': true,
          'user': LocalUser(uid: userData['id'].toString()),
          'userData': {
            'id': userData['id'],
            'nombre': userData['nombre'],
            'email': userData['email'],
            'rol': userRole,
            'roles': rolesList,
            'public_id': userData['id'].toString(),
          },
        };
      }

      return {'success': false, 'message': 'Credenciales incorrectas.'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Error de conexión.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  /// Inicia sesión con Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '32992727938-rreabr4tphbidr2gl683mom4ra8qpunv.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Inicio de sesión cancelado.'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        return {'success': false, 'message': 'No se pudo obtener el token de Google.'};
      }

      // Enviar el token a nuestro backend
      final response = await _api.post(
        '/google-login',
        data: {'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final userData = data['usuario'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', userData['nombre'] ?? '');
        
        final rolesList = List<String>.from(userData['roles'] ?? []);
        final userRole = userData['rol'] ?? 'inquilino';

        await prefs.setString('user_role', userRole);
        await prefs.setString('user_id', userData['id'].toString());

        return {
          'success': true,
          'user': LocalUser(uid: userData['id'].toString()),
          'userData': userData,
        };
      }

      return {'success': false, 'message': 'Error al autenticar con el servidor.'};
    } catch (e) {
      debugPrint('Error Google Sign In: $e');
      return {'success': false, 'message': 'Error al iniciar sesión con Google.'};
    }
  }

  /// Verifica si el token guardado es válido
  Future<Map<String, dynamic>?> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    try {
      final response = await _api.get('/me');
      if (response.statusCode == 200) {
        // Laravel Resources suelen envolver en 'data'
        Map<String, dynamic>? userData;
        if (response.data is Map) {
          if (response.data.containsKey('data')) {
            userData = Map<String, dynamic>.from(response.data['data']);
          } else {
            userData = Map<String, dynamic>.from(response.data);
          }
        }

        if (userData == null) return null;

        final rolesList =
            (userData['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        
        String userRole = 'inquilino';
        if (rolesList.isNotEmpty) {
          final lowerRoles = rolesList.map((r) => r.toLowerCase()).toList();
          // Priorizar rol Propietario si existe
          if (lowerRoles.contains('propietario') ||
              lowerRoles.contains('arrendador') ||
              lowerRoles.contains('admin') ||
              lowerRoles.contains('administrador')) {
            userRole = lowerRoles.firstWhere(
              (r) =>
                  r == 'propietario' ||
                  r == 'arrendador' ||
                  r == 'admin' ||
                  r == 'administrador',
              orElse: () => 'inquilino'
            );
          } else {
            userRole = lowerRoles[0];
          }
        }

        return {
          'id': userData['id'].toString(),
          'nombre': userData['nombre'] ?? '',
          'email': userData['email'] ?? '',
          'foto_perfil': userData['foto_perfil'],
          'rol': userRole,
          'roles': rolesList,
          'public_id': userData['id'].toString(),
        };
      }
    } catch (e) {
      debugPrint('Error verificando sesión: $e');
    }
    return null;
  }

  /// Registro en Laravel
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      final emailLimpio = Validators.sanitizeEmail(email);
      final nombreLimpio = Validators.sanitizeText(nombre, maxLength: 100);

      final response = await _api.post(
        '/register',
        data: {
          'nombre': nombreLimpio,
          'email': emailLimpio,
          'password': password,
          'password_confirmation': password,
          'rol': rol,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Después del registro, hacemos login automático o pedimos login
        return await signInWithEmail(email: emailLimpio, password: password);
      }

      return {'success': false, 'message': 'No se pudo completar el registro.'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Error en el registro.',
      };
    }
  }

  Future<void> signOut() async {
    try {
      await _api.post('/logout');
    } catch (e) {
      // Ignorar error si el token ya no es válido
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    // TODO: Implementar en Laravel
    return {
      'success': true,
      'message': 'Si el email está registrado, recibirás un correo.',
    };
  }

  Future<void> updateBaseUrl(String url) async {
    await _api.setCustomBaseUrl(url);
  }

  String get currentBaseUrl => _api.currentBaseUrl;
}
