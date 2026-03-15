class SesionActual {
  static String? usuarioId; // Firebase UID
  static String nombre = '';
  static String email = '';
  static String rol = '';
  static List<String> todosLosRoles = [];
  static String? publicId; // ID corto de 4 dígitos

  static bool get esPropietario {
    final r = rol.toLowerCase().trim();
    return r == 'arrendador' ||
        r == 'propietario' ||
        r == 'admin' ||
        r == 'administrador';
  }

  static bool get esAdmin {
    final r = rol.toLowerCase().trim();
    return r == 'admin' || r == 'administrador';
  }

  static bool get tieneMultiplesRoles => todosLosRoles.length > 1;

  static bool get canSwitchDashboard {
    return todosLosRoles.any((r) {
      final lr = r.toLowerCase().trim();
      return lr == 'arrendador' ||
          lr == 'propietario' ||
          lr == 'admin' ||
          lr == 'administrador';
    });
  }
}
