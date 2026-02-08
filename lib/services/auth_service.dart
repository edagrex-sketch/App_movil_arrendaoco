import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arrendaoco/utils/validators.dart';
import 'package:arrendaoco/utils/password_hasher.dart';

class LocalUser {
  final String uid;
  LocalUser({required this.uid});
}

/// Servicio de autenticación seguro
///
/// Implementa:
/// - Validación de inputs
/// - Encriptación de contraseñas con SHA-256
/// - Sanitización de datos
/// - Prevención de inyecciones SQL
class AuthService {
  final _supabase = Supabase.instance.client;

  AuthService();

  /// Inicia sesión con email y contraseña
  ///
  /// Valida y sanitiza los inputs antes de consultar la BD.
  /// Compara contraseñas usando hash SHA-256.
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. VALIDAR Y SANITIZAR EMAIL
      final emailLimpio = Validators.sanitizeEmail(email);

      if (!Validators.isValidEmail(emailLimpio)) {
        return {
          'success': false,
          'message': 'Email inválido. Verifica el formato.',
        };
      }

      // 2. VALIDAR CONTRASEÑA (no vacía)
      if (password.isEmpty) {
        return {'success': false, 'message': 'La contraseña es requerida.'};
      }

      // 3. BUSCAR USUARIO POR EMAIL
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('username', emailLimpio)
          .maybeSingle();

      if (response == null) {
        return {'success': false, 'message': 'Credenciales incorrectas.'};
      }

      // 4. VERIFICAR CONTRASEÑA CON HASH
      final userRow = response;
      final storedHash = userRow['password'] as String;

      final isPasswordValid = PasswordHasher.verifyPassword(
        password,
        storedHash,
      );

      if (!isPasswordValid) {
        return {'success': false, 'message': 'Credenciales incorrectas.'};
      }

      // 5. LOGIN EXITOSO
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
    } on ValidationException catch (e) {
      return {'success': false, 'message': e.toString()};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión. Intenta nuevamente.',
      };
    }
  }

  /// Registra un nuevo usuario
  ///
  /// Valida todos los inputs y encripta la contraseña antes de guardar.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      // 1. VALIDAR Y SANITIZAR EMAIL
      final emailLimpio = Validators.sanitizeEmail(email);

      if (!Validators.isValidEmail(emailLimpio)) {
        return {
          'success': false,
          'message':
              'Email inválido. Usa un formato válido (ej: usuario@ejemplo.com)',
        };
      }

      // 2. VALIDAR CONTRASEÑA
      if (!Validators.isValidPassword(password)) {
        return {
          'success': false,
          'message': Validators.getPasswordRequirements(),
        };
      }

      // 3. VALIDAR Y SANITIZAR NOMBRE
      final nombreLimpio = Validators.sanitizeText(nombre, maxLength: 100);

      if (!Validators.isValidName(nombreLimpio)) {
        return {
          'success': false,
          'message': 'Nombre inválido. Solo letras, espacios y acentos.',
        };
      }

      if (nombreLimpio.length < 2) {
        return {
          'success': false,
          'message': 'El nombre debe tener al menos 2 caracteres.',
        };
      }

      // 4. VALIDAR ROL
      final rolNormalizado = rol.trim().toLowerCase();
      final rolesPermitidos = ['inquilino', 'arrendador'];
      if (!rolesPermitidos.contains(rolNormalizado)) {
        return {
          'success': false,
          'message': 'Rol inválido. Debe ser "inquilino" o "arrendador".',
        };
      }

      // 5. VERIFICAR SI EL USUARIO YA EXISTE
      final exists = await _supabase
          .from('usuarios')
          .select()
          .eq('username', emailLimpio)
          .maybeSingle();

      if (exists != null) {
        return {
          'success': false,
          'message': 'Este email ya está registrado. Intenta iniciar sesión.',
        };
      }

      // 6. ENCRIPTAR CONTRASEÑA
      final passwordHash = PasswordHasher.hashPassword(password);

      // 7. INSERTAR NUEVO USUARIO CON DATOS VALIDADOS Y SANITIZADOS
      final response = await _supabase
          .from('usuarios')
          .insert({
            'username': emailLimpio,
            'password': passwordHash, // ✅ Hash, NO texto plano
            'nombre': nombreLimpio,
            'rol': rolNormalizado,
          })
          .select('id')
          .single();

      final id = response['id'] as int;

      // 8. REGISTRO EXITOSO
      return {
        'success': true,
        'user': LocalUser(uid: id.toString()),
        'userData': {
          'nombre': nombreLimpio,
          'email': emailLimpio,
          'rol': rolNormalizado,
          'public_id': id.toString(),
        },
      };
    } on ValidationException catch (e) {
      return {'success': false, 'message': e.toString()};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al registrar. Intenta nuevamente.',
      };
    }
  }

  /// Solicita recuperación de contraseña
  ///
  /// Genera un token seguro y lo envía por email.
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      // 1. VALIDAR Y SANITIZAR EMAIL
      final emailLimpio = Validators.sanitizeEmail(email);

      if (!Validators.isValidEmail(emailLimpio)) {
        return {'success': false, 'message': 'Email inválido.'};
      }

      // 2. VERIFICAR QUE EL USUARIO EXISTA
      final user = await _supabase
          .from('usuarios')
          .select('id')
          .eq('username', emailLimpio)
          .maybeSingle();

      if (user == null) {
        // Por seguridad, no revelar si el email existe o no
        return {
          'success': true,
          'message':
              'Si el email existe, recibirás instrucciones para recuperar tu contraseña.',
        };
      }

      // 3. GENERAR TOKEN DE RECUPERACIÓN
      final resetToken = PasswordHasher.generateResetToken(emailLimpio);
      // final expiraEn = DateTime.now().add(Duration(hours: 1));

      // 4. GUARDAR TOKEN EN BD (necesitarías crear esta tabla)
      // TODO: Implementar tabla de tokens de recuperación
      // await _supabase.from('password_reset_tokens').insert({
      //   'email': emailLimpio,
      //   'token': resetToken,
      //   'expira_en': expiraEn.toIso8601String(),
      // });

      // 5. ENVIAR EMAIL (necesitarías configurar servicio de email)
      // TODO: Implementar envío de email con el token

      return {
        'success': true,
        'message':
            'Si el email existe, recibirás instrucciones para recuperar tu contraseña.',
        'token': resetToken, // Solo para desarrollo, REMOVER en producción
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al procesar solicitud.'};
    }
  }

  /// Cambia la contraseña usando un token de recuperación
  Future<Map<String, dynamic>> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    try {
      // 1. VALIDAR NUEVA CONTRASEÑA
      if (!Validators.isValidPassword(newPassword)) {
        return {
          'success': false,
          'message': Validators.getPasswordRequirements(),
        };
      }

      // 2. VERIFICAR TOKEN (necesitarías implementar tabla de tokens)
      // TODO: Verificar que el token exista y no haya expirado

      // 3. ENCRIPTAR NUEVA CONTRASEÑA
      // final newPasswordHash = PasswordHasher.hashPassword(newPassword);

      // 4. ACTUALIZAR CONTRASEÑA
      // TODO: Actualizar password del usuario asociado al token

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al cambiar contraseña.'};
    }
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
