class SesionActual {
  static String? usuarioId; // Firebase UID
  static String nombre = '';
  static String email = '';
  static String rol = '';
  static List<String> todosLosRoles = [];
  static String? publicId; // ID corto de 4 dígitos
  static bool stripeOnboardingCompleted = false;

  static bool get esPropietario {
    final validRoles = ['arrendador', 'propietario', 'admin', 'administrador'];
    
    // Revisar rol principal
    if (validRoles.contains(rol.toLowerCase().trim())) return true;
    
    // Revisar lista completa
    return todosLosRoles.any((r) => validRoles.contains(r.toLowerCase().trim()));
  }

  static bool get esAdmin {
    final validRoles = ['admin', 'administrador'];
    
    // Revisar rol principal
    if (validRoles.contains(rol.toLowerCase().trim())) return true;
    
    // Revisar lista completa
    return todosLosRoles.any((r) => validRoles.contains(r.toLowerCase().trim()));
  }

  static bool get tieneMultiplesRoles => todosLosRoles.length > 1;

  static bool get canSwitchDashboard {
    return usuarioId != null;
  }
}
