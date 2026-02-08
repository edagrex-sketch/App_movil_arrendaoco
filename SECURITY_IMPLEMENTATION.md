# 🔐 Guía de Implementación de Seguridad - AuthService

## ✅ Cambios Implementados

### **1. AuthService Seguro**
- ✅ Validación de todos los inputs
- ✅ Sanitización de datos
- ✅ Encriptación SHA-256 de contraseñas
- ✅ Prevención de inyecciones SQL
- ✅ Mensajes de error seguros

### **2. Utilidades de Seguridad**
- ✅ `Validators` - Validación y sanitización
- ✅ `PasswordHasher` - Encriptación de contraseñas
- ✅ `PasswordMigration` - Script de migración

---

## 🚀 Pasos para Implementar

### **Paso 1: Migrar Contraseñas Existentes** ⚠️ CRÍTICO

Si ya tienes usuarios registrados con contraseñas en texto plano, DEBES ejecutar la migración:

```dart
// Crear archivo: lib/scripts/migrate_passwords.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arrendaoco/utils/password_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase (usa tus credenciales)
  await Supabase.initialize(
    url: 'TU_SUPABASE_URL',
    anonKey: 'TU_SUPABASE_ANON_KEY',
  );
  
  final migration = PasswordMigration();
  
  print('⚠️  ADVERTENCIA: Este script modificará todas las contraseñas en la BD');
  print('   Asegúrate de tener un backup antes de continuar.\n');
  
  // Ejecutar migración
  await migration.migrate();
  
  // Verificar resultado
  await migration.verify();
  
  print('\n✅ Proceso completado. Puedes cerrar esta ventana.');
}
```

**Ejecutar:**
```bash
flutter run lib/scripts/migrate_passwords.dart
```

---

### **Paso 2: Actualizar Pantallas de Login/Registro**

No necesitas cambiar mucho en tus pantallas, solo asegúrate de mostrar los mensajes de error:

```dart
// En tu pantalla de registro
Future<void> _registrar() async {
  final result = await AuthService().signUp(
    email: _emailController.text,
    password: _passwordController.text,
    nombre: _nombreController.text,
    rol: _rolSeleccionado,
  );
  
  if (result['success']) {
    // Registro exitoso
    Navigator.pushReplacement(context, ...);
  } else {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### **Paso 3: Verificar que Funciona**

1. **Registra un nuevo usuario:**
   - Email: `test@gmail.com`
   - Password: `TestPass123`
   - Nombre: `Usuario Prueba`

2. **Verifica en Supabase:**
   - Ve a tu tabla `usuarios`
   - La contraseña debe ser un hash de 64 caracteres
   - Ejemplo: `a3f8d9e2c1b4567890abcdef1234567890abcdef1234567890abcdef12345678`

3. **Intenta iniciar sesión:**
   - Usa las mismas credenciales
   - Debe funcionar correctamente

---

## 📊 Comparación: Antes vs Ahora

### **ANTES (INSEGURO) ❌**

```dart
// Login
.eq('password', password)  // Compara texto plano

// Registro
.insert({
  'password': password  // Guarda texto plano
})

// En BD:
| email          | password      |
|----------------|---------------|
| user@gmail.com | MiPass123     | ← ¡Visible!
```

### **AHORA (SEGURO) ✅**

```dart
// Login
final hash = PasswordHasher.hashPassword(password);
final isValid = PasswordHasher.verifyPassword(password, storedHash);

// Registro
.insert({
  'password': PasswordHasher.hashPassword(password)  // Hash SHA-256
})

// En BD:
| email          | password                                                          |
|----------------|-------------------------------------------------------------------|
| user@gmail.com | a3f8d9e2c1b4567890abcdef1234567890abcdef1234567890abcdef12345678 |
                  ↑ Imposible de revertir
```

---

## 🔍 Validaciones Implementadas

### **Email:**
- ✅ Formato RFC 5322
- ✅ Máximo 254 caracteres
- ✅ Sanitización (trim + lowercase)

### **Contraseña:**
- ✅ Mínimo 8 caracteres
- ✅ Al menos 1 mayúscula
- ✅ Al menos 1 minúscula
- ✅ Al menos 1 número
- ✅ Máximo 128 caracteres

### **Nombre:**
- ✅ Solo letras, espacios, acentos
- ✅ Mínimo 2 caracteres
- ✅ Máximo 100 caracteres
- ✅ Sanitización de espacios

### **Rol:**
- ✅ Solo "inquilino" o "arrendador"

---

## 🛡️ Protecciones Implementadas

| Ataque | Protección |
|--------|------------|
| **SQL Injection** | ✅ Validación de inputs + Supabase prepared statements |
| **XSS** | ✅ Sanitización de texto |
| **Contraseñas débiles** | ✅ Validación de complejidad |
| **Fuerza bruta** | ⚠️ Pendiente: Rate limiting |
| **Enumeración de usuarios** | ✅ Mensajes genéricos en reset password |

---

## ⚠️ Notas Importantes

### **1. Usuarios Existentes**
Después de la migración, los usuarios usarán las MISMAS contraseñas que antes. El sistema ahora las compara usando hash en lugar de texto plano.

### **2. Contraseñas Olvidadas**
Si un usuario olvida su contraseña ANTES de la migración, NO podrás recuperarla (está en texto plano en la BD). Después de la migración, tampoco (está hasheada). Deberás implementar reset de contraseña.

### **3. Backup**
SIEMPRE haz un backup de tu BD antes de ejecutar la migración.

---

## 🎯 Próximos Pasos Recomendados

1. ✅ **Ejecutar migración de contraseñas**
2. ✅ **Probar login/registro**
3. ⏭️ **Implementar reset de contraseña completo**
4. ⏭️ **Agregar rate limiting (límite de intentos)**
5. ⏭️ **Configurar Row Level Security en Supabase**
6. ⏭️ **Implementar 2FA (autenticación de dos factores)**

---

## 🆘 Solución de Problemas

### **Error: "Credenciales incorrectas" después de migración**

**Causa:** La migración no se ejecutó correctamente.

**Solución:**
```dart
// Verificar migración
final migration = PasswordMigration();
await migration.verify();
```

### **Error: "Password inválido" al registrar**

**Causa:** La contraseña no cumple los requisitos.

**Solución:**
```dart
// Mostrar requisitos al usuario
print(Validators.getPasswordRequirements());
```

---

## 📞 Contacto

Si tienes dudas sobre la implementación, revisa:
- `lib/services/auth_service.dart` - Servicio actualizado
- `lib/utils/validators.dart` - Validaciones
- `lib/utils/password_hasher.dart` - Encriptación
- `test/utils_test.dart` - Tests de ejemplo
