import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arrendaoco/utils/password_hasher.dart';

/// Script de migración para convertir contraseñas en texto plano a hash SHA-256
///
/// ⚠️ IMPORTANTE: Ejecutar SOLO UNA VEZ antes de desplegar la nueva versión
///
/// Este script:
/// 1. Lee todos los usuarios de la BD
/// 2. Convierte sus contraseñas de texto plano a hash SHA-256
/// 3. Actualiza la BD con los hashes
///
/// Después de ejecutar este script, las contraseñas estarán seguras.
class PasswordMigration {
  final _supabase = Supabase.instance.client;

  /// Ejecuta la migración de contraseñas
  Future<void> migrate() async {
    print('🔄 Iniciando migración de contraseñas...\n');

    try {
      // 1. Obtener todos los usuarios
      final usuarios = await _supabase
          .from('usuarios')
          .select('id, username, password');

      if (usuarios.isEmpty) {
        print('✅ No hay usuarios para migrar.');
        return;
      }

      print('📊 Usuarios encontrados: ${usuarios.length}\n');

      int migrados = 0;
      int errores = 0;

      // 2. Procesar cada usuario
      for (var usuario in usuarios) {
        final id = usuario['id'];
        final email = usuario['username'];
        final passwordActual = usuario['password'] as String;

        try {
          // Verificar si ya está hasheada (hash SHA-256 tiene 64 caracteres)
          if (passwordActual.length == 64 &&
              RegExp(r'^[a-f0-9]{64}$').hasMatch(passwordActual)) {
            print(
              '⏭️  Usuario $email ya tiene contraseña hasheada. Saltando...',
            );
            continue;
          }

          // 3. Generar hash de la contraseña actual
          final passwordHash = PasswordHasher.hashPassword(passwordActual);

          // 4. Actualizar en la BD
          await _supabase
              .from('usuarios')
              .update({'password': passwordHash})
              .eq('id', id);

          migrados++;
          print('✅ Migrado: $email');
          print('   Contraseña original: ${_maskPassword(passwordActual)}');
          print('   Hash generado: ${passwordHash.substring(0, 20)}...\n');
        } catch (e) {
          errores++;
          print('❌ Error al migrar $email: $e\n');
        }
      }

      // 5. Resumen
      print('\n' + '=' * 50);
      print('📊 RESUMEN DE MIGRACIÓN');
      print('=' * 50);
      print('Total de usuarios: ${usuarios.length}');
      print('✅ Migrados exitosamente: $migrados');
      print('❌ Errores: $errores');
      print('⏭️  Ya hasheados: ${usuarios.length - migrados - errores}');
      print('=' * 50 + '\n');

      if (migrados > 0) {
        print('🎉 ¡Migración completada!');
        print(
          '⚠️  IMPORTANTE: Los usuarios deberán usar sus contraseñas originales para iniciar sesión.',
        );
        print('   El sistema ahora las comparará usando hash SHA-256.\n');
      }
    } catch (e) {
      print('❌ Error fatal en la migración: $e');
      rethrow;
    }
  }

  /// Enmascara una contraseña para mostrarla de forma segura
  String _maskPassword(String password) {
    if (password.length <= 4) {
      return '*' * password.length;
    }
    return password.substring(0, 2) +
        ('*' * (password.length - 4)) +
        password.substring(password.length - 2);
  }

  /// Verifica que la migración fue exitosa
  Future<void> verify() async {
    print('🔍 Verificando migración...\n');

    try {
      final usuarios = await _supabase
          .from('usuarios')
          .select('id, username, password');

      int hasheados = 0;
      int textoPlano = 0;

      for (var usuario in usuarios) {
        final password = usuario['password'] as String;

        // Verificar si es un hash SHA-256 válido (64 caracteres hexadecimales)
        if (password.length == 64 &&
            RegExp(r'^[a-f0-9]{64}$').hasMatch(password)) {
          hasheados++;
        } else {
          textoPlano++;
          print(
            '⚠️  Usuario ${usuario['username']} aún tiene contraseña en texto plano',
          );
        }
      }

      print('\n' + '=' * 50);
      print('📊 RESULTADO DE VERIFICACIÓN');
      print('=' * 50);
      print('Total de usuarios: ${usuarios.length}');
      print('✅ Con hash SHA-256: $hasheados');
      print('❌ En texto plano: $textoPlano');
      print('=' * 50 + '\n');

      if (textoPlano == 0) {
        print('🎉 ¡Todas las contraseñas están hasheadas correctamente!');
      } else {
        print('⚠️  Aún hay $textoPlano contraseñas en texto plano.');
        print('   Ejecuta la migración nuevamente.');
      }
    } catch (e) {
      print('❌ Error en la verificación: $e');
      rethrow;
    }
  }
}

/// Ejemplo de uso:
/// 
/// ```dart
/// void main() async {
///   // Inicializar Supabase
///   await Supabase.initialize(
///     url: 'TU_SUPABASE_URL',
///     anonKey: 'TU_SUPABASE_ANON_KEY',
///   );
///   
///   final migration = PasswordMigration();
///   
///   // Ejecutar migración
///   await migration.migrate();
///   
///   // Verificar resultado
///   await migration.verify();
/// }
/// ```
