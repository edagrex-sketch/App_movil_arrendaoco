class Parser {
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int paramInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      // int.tryParse falla con "1.00", "144.00" (decimales de Laravel)
      // Primero intentar como double y convertir
      final asDouble = double.tryParse(value);
      if (asDouble != null) return asDouble.toInt();
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
