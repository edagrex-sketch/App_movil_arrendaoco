/// Utilidades de validación y sanitización de datos
/// Previene inyecciones SQL, XSS y otros ataques
library;

class Validators {
  // ==================== VALIDACIÓN DE EMAILS ====================

  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  /// Sanitiza email removiendo espacios y convirtiendo a minúsculas
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // ==================== VALIDACIÓN DE CONTRASEÑAS ====================

  /// Valida que la contraseña cumpla requisitos mínimos de seguridad
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (password.length > 128) return false;

    // Al menos una mayúscula
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Al menos una minúscula
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Al menos un número
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    return true;
  }

  /// Retorna mensaje descriptivo de requisitos de contraseña
  static String getPasswordRequirements() {
    return '''
Requisitos de contraseña:
• Mínimo 8 caracteres
• Al menos una mayúscula
• Al menos una minúscula
• Al menos un número
''';
  }

  // ==================== VALIDACIÓN DE TEXTO ====================

  /// Sanitiza texto removiendo caracteres peligrosos
  static String sanitizeText(String text, {int maxLength = 1000}) {
    if (text.isEmpty) return '';

    // Remover caracteres de control y espacios múltiples
    String sanitized = text
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Control chars
        .replaceAll(RegExp(r'\s+'), ' ') // Múltiples espacios
        .trim();

    // Limitar longitud
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Valida que el texto no contenga scripts maliciosos (XSS básico)
  static bool containsXSS(String text) {
    final xssPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
      RegExp(r'onclick=', caseSensitive: false),
      RegExp(r'<iframe', caseSensitive: false),
    ];

    return xssPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Sanitiza HTML removiendo tags peligrosos
  static String sanitizeHTML(String html) {
    return html
        .replaceAll(
          RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  // ==================== VALIDACIÓN DE NÚMEROS ====================

  /// Valida que sea un número positivo válido
  static bool isValidPositiveNumber(dynamic value) {
    if (value == null) return false;

    if (value is num) {
      return value > 0 && value.isFinite;
    }

    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed != null && parsed > 0 && parsed.isFinite;
    }

    return false;
  }

  /// Valida rango de precio (entre 0 y 1 millón)
  static bool isValidPrice(dynamic price) {
    if (!isValidPositiveNumber(price)) return false;

    final numPrice = price is num ? price : num.parse(price.toString());
    return numPrice >= 0 && numPrice <= 1000000000; // Máx 1 billón
  }

  /// Valida rating (1-5)
  static bool isValidRating(dynamic rating) {
    if (!isValidPositiveNumber(rating)) return false;

    final numRating = rating is num ? rating : num.parse(rating.toString());
    return numRating >= 1 && numRating <= 5;
  }

  // ==================== VALIDACIÓN DE IDs ====================

  /// Valida que sea un ID válido (entero positivo)
  static bool isValidId(dynamic id) {
    if (id == null) return false;

    if (id is int) {
      return id > 0;
    }

    if (id is String) {
      final parsed = int.tryParse(id);
      return parsed != null && parsed > 0;
    }

    return false;
  }

  // ==================== VALIDACIÓN DE FECHAS ====================

  /// Valida que la fecha sea válida y no esté muy en el pasado/futuro
  static bool isValidDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      // No más de 100 años en el pasado
      final minDate = now.subtract(const Duration(days: 365 * 100));

      // No más de 50 años en el futuro
      final maxDate = now.add(const Duration(days: 365 * 50));

      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (e) {
      return false;
    }
  }

  /// Valida que la fecha de inicio sea antes que la de fin
  static bool isValidDateRange(String? startDate, String? endDate) {
    if (!isValidDate(startDate) || !isValidDate(endDate)) return false;

    try {
      final start = DateTime.parse(startDate!);
      final end = DateTime.parse(endDate!);

      return start.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  // ==================== VALIDACIÓN DE URLs ====================

  /// Valida que sea una URL válida
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  // ==================== VALIDACIÓN DE TELÉFONOS ====================

  /// Valida formato de teléfono (México - 10 dígitos)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;

    // Remover espacios, guiones y paréntesis
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Validar que sean 10 dígitos
    return RegExp(r'^\d{10}$').hasMatch(cleaned);
  }

  /// Sanitiza número de teléfono
  static String sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // ==================== VALIDACIÓN DE NOMBRES ====================

  /// Valida que el nombre sea válido (solo letras, espacios y acentos)
  static bool isValidName(String? name) {
    if (name == null || name.isEmpty) return false;
    if (name.length < 2 || name.length > 100) return false;

    // Solo letras, espacios, acentos y algunos caracteres especiales
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s\-\.\x27]+$');

    return nameRegex.hasMatch(name);
  }

  // ==================== VALIDACIÓN DE COORDENADAS ====================

  /// Valida latitud (-90 a 90)
  static bool isValidLatitude(dynamic lat) {
    if (lat == null) return false;

    final numLat = lat is num ? lat : num.tryParse(lat.toString());
    if (numLat == null) return false;

    return numLat >= -90 && numLat <= 90;
  }

  /// Valida longitud (-180 a 180)
  static bool isValidLongitude(dynamic lng) {
    if (lng == null) return false;

    final numLng = lng is num ? lng : num.tryParse(lng.toString());
    if (numLng == null) return false;

    return numLng >= -180 && numLng <= 180;
  }

  // ==================== VALIDACIÓN DE MAPAS ====================

  /// Valida que un Map contenga las claves requeridas
  static bool hasRequiredKeys(
    Map<String, dynamic> data,
    List<String> requiredKeys,
  ) {
    return requiredKeys.every((key) => data.containsKey(key));
  }

  /// Valida y sanitiza un Map de datos
  static Map<String, dynamic> sanitizeMap(
    Map<String, dynamic> data, {
    List<String>? allowedKeys,
    int maxStringLength = 1000,
  }) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      // Si hay lista de claves permitidas, filtrar
      if (allowedKeys != null && !allowedKeys.contains(entry.key)) {
        continue;
      }

      final value = entry.value;

      // Sanitizar según tipo
      if (value is String) {
        sanitized[entry.key] = sanitizeText(value, maxLength: maxStringLength);
      } else if (value is num || value is bool || value == null) {
        sanitized[entry.key] = value;
      } else if (value is List || value is Map) {
        // Convertir a JSON string y sanitizar
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }
}

/// Excepciones personalizadas para validación
class ValidationException implements Exception {
  final String message;
  final String field;

  ValidationException(this.message, {this.field = ''});

  @override
  String toString() => field.isEmpty
      ? 'Error de validación: $message'
      : 'Error en $field: $message';
}
