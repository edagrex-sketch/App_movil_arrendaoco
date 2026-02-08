# Script para Remover Firebase

## Archivos a Modificar:

### 1. pubspec.yaml
Remover:
```yaml
firebase_core: ^4.2.1
firebase_messaging: ^16.0.4
```

### 2. android/app/build.gradle.kts
Remover línea:
```kotlin
id("com.google.gms.google-services")
```

### 3. android/build.gradle.kts
Remover:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### 4. android/app/google-services.json
Eliminar este archivo

### 5. lib/main.dart
Remover:
```dart
import 'package:firebase_core/firebase_core.dart';

// Y el bloque de inicialización:
try {
  await Firebase.initializeApp();
  debugPrint('✅ Firebase inicializado');
} catch (e) {
  debugPrint('⚠️ Error inicializando Firebase...');
}
```

### 6. lib/services/fcm_service.dart
Eliminar este archivo completo

### 7. Reemplazar notificaciones
Usar solo `flutter_local_notifications` para notificaciones locales
