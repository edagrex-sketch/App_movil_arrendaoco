import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Servicio para encriptación segura de contraseñas
/// Usa SHA-256 con salt para proteger contraseñas
class PasswordHasher {
  // Salt único para tu aplicación (CAMBIAR EN PRODUCCIÓN)
  static const String _appSalt = 'ArrendaOco_2025_SecureApp';

  /// Genera hash seguro de una contraseña
  ///
  /// Usa SHA-256 con salt para proteger la contraseña.
  /// NUNCA almacenes contraseñas en texto plano.
  ///
  /// Ejemplo:
  /// ```dart
  /// final hash = PasswordHasher.hashPassword('MiContraseña123');
  /// ```
  static String hashPassword(String password) {
    // Combinar contraseña con salt
    final combined = '$password$_appSalt';

    // Generar hash SHA-256
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// Verifica si una contraseña coincide con un hash
  ///
  /// Ejemplo:
  /// ```dart
  /// final isValid = PasswordHasher.verifyPassword('MiContraseña123', storedHash);
  /// ```
  static bool verifyPassword(String password, String storedHash) {
    final newHash = hashPassword(password);
    return newHash == storedHash;
  }

  /// Genera un hash temporal para recuperación de contraseña
  ///
  /// Combina email + timestamp para crear token único
  static String generateResetToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$email$timestamp$_appSalt';

    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }
}
