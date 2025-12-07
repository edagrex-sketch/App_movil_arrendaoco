# Guía para Crear APK de ArrendaOco

## 🚀 Pasos Rápidos

### 1. APK de Debug (Para Pruebas Inmediatas)

**Comando:**
```bash
flutter build apk --debug
```

**Características:**
- ⚡ Compilación rápida
- 🐛 Incluye herramientas de debugging
- 📦 Archivo más grande (~50-80 MB)
- ✅ No requiere configuración adicional

**Ubicación del APK:**
```
build\app\outputs\flutter-apk\app-debug.apk
```

**Cuándo usar:** Para probar en tu dispositivo o compartir con testers.

---

### 2. APK de Release (Para Distribución)

**Comando:**
```bash
flutter build apk --release
```

**Características:**
- 🎯 Optimizado y comprimido
- 📦 Archivo más pequeño (~30-50 MB)
- ⚡ Mejor rendimiento
- ⚠️ Actualmente firmado con debug key (temporal)

**Ubicación del APK:**
```
build\app\outputs\flutter-apk\app-release.apk
```

**Cuándo usar:** Para distribución directa (fuera de tiendas) o pruebas de rendimiento.

---

### 3. APK Split por ABI (Recomendado)

**Comando:**
```bash
flutter build apk --split-per-abi --release
```

**Características:**
- 📱 Crea 3 APKs separados (uno por arquitectura)
- 📦 Archivos mucho más pequeños (~15-25 MB cada uno)
- ✅ Mejor para distribución directa

**Ubicación de los APKs:**
```
build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk  (32-bit ARM)
build\app\outputs\flutter-apk\app-arm64-v8a-release.apk    (64-bit ARM - más común)
build\app\outputs\flutter-apk\app-x86_64-release.apk       (Emuladores)
```

**Cuándo usar:** Para compartir con usuarios finales. La mayoría de dispositivos modernos usan `arm64-v8a`.

---

### 4. App Bundle (Para Google Play Store)

**Comando:**
```bash
flutter build appbundle --release
```

**Características:**
- 🏪 Formato requerido por Google Play Store
- 📦 Google Play optimiza automáticamente
- ✅ Usuarios descargan solo lo necesario para su dispositivo

**Ubicación del Bundle:**
```
build\app\outputs\bundle\release\app-release.aab
```

**Cuándo usar:** Solo para subir a Google Play Store.

---

## 📋 Proceso Completo Paso a Paso

### Opción A: APK para Pruebas Rápidas

1. **Abre la terminal en el directorio del proyecto:**
   ```bash
   cd c:\movil\integradora\arrendaoco
   ```

2. **Ejecuta el comando:**
   ```bash
   flutter build apk --debug
   ```

3. **Espera a que termine** (puede tomar 2-5 minutos)

4. **Encuentra tu APK:**
   ```
   build\app\outputs\flutter-apk\app-debug.apk
   ```

5. **Instala en tu dispositivo:**
   - Conecta tu teléfono por USB
   - Ejecuta: `flutter install`
   - O copia el APK al teléfono e instálalo manualmente

---

### Opción B: APK Optimizado para Distribución

1. **Limpia builds anteriores (opcional pero recomendado):**
   ```bash
   flutter clean
   ```

2. **Obtén las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Crea el APK de release:**
   ```bash
   flutter build apk --release --split-per-abi
   ```

4. **Encuentra tus APKs:**
   ```
   build\app\outputs\flutter-apk\
   ```

5. **Comparte el APK apropiado:**
   - Para la mayoría de dispositivos: `app-arm64-v8a-release.apk`
   - Para dispositivos antiguos: `app-armeabi-v7a-release.apk`

---

## 🔧 Solución de Problemas

### Error: "Gradle build failed"

**Solución:**
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Error: "SDK location not found"

**Solución:**
1. Verifica que Android SDK esté instalado
2. Configura la variable de entorno ANDROID_HOME
3. O crea `android/local.properties`:
   ```
   sdk.dir=C:\\Users\\TuUsuario\\AppData\\Local\\Android\\Sdk
   ```

### APK muy grande

**Solución:**
- Usa `--split-per-abi` para reducir tamaño
- Usa `--release` en lugar de `--debug`
- Habilita ProGuard (ya está configurado en tu proyecto)

### Error de firma en release

**Nota:** Actualmente tu app usa la firma de debug para release. Para producción, necesitarás:
1. Crear un keystore
2. Configurar `key.properties`
3. Actualizar `build.gradle.kts`

(Ver `PUBLICACION_README.md` para detalles)

---

## 📱 Instalación del APK

### Método 1: Desde el Dispositivo

1. Copia el APK a tu teléfono (por cable, email, Drive, etc.)
2. Abre el archivo APK en tu teléfono
3. Permite "Instalar desde fuentes desconocidas" si se solicita
4. Toca "Instalar"

### Método 2: Con ADB (Android Debug Bridge)

```bash
# Conecta tu dispositivo por USB
# Habilita "Depuración USB" en el teléfono

# Instala el APK
adb install build\app\outputs\flutter-apk\app-release.apk

# O usa Flutter directamente
flutter install
```

### Método 3: Desde Flutter (más fácil)

```bash
# Conecta tu dispositivo
# Ejecuta:
flutter run --release
```

---

## 📊 Comparación de Tamaños Aproximados

| Tipo de Build | Tamaño Aproximado | Uso |
|---------------|-------------------|-----|
| Debug APK | 50-80 MB | Pruebas de desarrollo |
| Release APK | 30-50 MB | Distribución directa |
| Split APK (arm64) | 15-25 MB | Distribución optimizada |
| App Bundle | 25-40 MB | Google Play Store |

---

## ✅ Checklist Antes de Distribuir

- [ ] Probaste el APK en un dispositivo real
- [ ] Verificaste que todas las funciones funcionan
- [ ] No hay datos de prueba o URLs de desarrollo
- [ ] Las notificaciones funcionan correctamente
- [ ] Los permisos se solicitan apropiadamente
- [ ] La app no crashea al iniciar
- [ ] Probaste en diferentes versiones de Android si es posible

---

## 🎯 Recomendación

**Para pruebas:** Usa `flutter build apk --debug`

**Para compartir con usuarios:** Usa `flutter build apk --split-per-abi --release` y comparte el APK `arm64-v8a`

**Para Google Play Store:** Usa `flutter build appbundle --release`

---

## 📞 Comandos Útiles

```bash
# Ver dispositivos conectados
flutter devices

# Limpiar builds anteriores
flutter clean

# Ver logs en tiempo real
flutter logs

# Desinstalar la app del dispositivo
adb uninstall com.example.arrendaoco

# Ver información del APK
aapt dump badging build\app\outputs\flutter-apk\app-release.apk
```

---

## 🔐 Nota sobre Firma

Tu app actualmente está configurada para usar la firma de debug en builds de release. Esto está bien para:
- ✅ Pruebas internas
- ✅ Distribución directa a usuarios de confianza
- ✅ Testing beta

Para publicar en Google Play Store, necesitarás crear un keystore de producción (ver `PUBLICACION_README.md`).
