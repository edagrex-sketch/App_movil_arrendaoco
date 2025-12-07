# ArrendaOco - Preparación para Publicación en Tiendas

## ✅ Configuraciones Completadas

### Android (Google Play Store)
- ✅ **AndroidManifest.xml** actualizado con:
  - Descripciones de permisos (ubicación, cámara, almacenamiento)
  - Configuración de seguridad de red
  - Eliminación de permisos duplicados
  
- ✅ **build.gradle.kts** configurado con:
  - minSdk: 21
  - targetSdk: 34
  - ProGuard/R8 habilitado para ofuscación
  - Shrinking de recursos habilitado

- ✅ **ProGuard rules** creadas para proteger el código

### iOS (Apple App Store)
- ✅ **Info.plist** actualizado con:
  - NSLocationWhenInUseUsageDescription
  - NSCameraUsageDescription
  - NSPhotoLibraryUsageDescription
  - NSPhotoLibraryAddUsageDescription

### Documentación
- ✅ **Política de Privacidad** (`privacy_policy.md`)
- ✅ **Términos y Condiciones** (`terms_of_service.md`)
- ✅ **Información para Tiendas** (`store_listing.md`)

## ⚠️ Pasos Pendientes (Requieren Acción Manual)

### 1. Crear Keystore para Android
Para firmar tu aplicación de release, necesitas crear un keystore:

```bash
keytool -genkey -v -keystore c:\movil\integradora\arrendaoco\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**IMPORTANTE**: Guarda el keystore y las contraseñas en un lugar seguro. Los necesitarás para todas las actualizaciones futuras.

### 2. Configurar key.properties
Crea el archivo `android/key.properties` con:

```properties
storePassword=<contraseña-del-keystore>
keyPassword=<contraseña-de-la-key>
keyAlias=upload
storeFile=<ruta-al-keystore.jks>
```

Luego actualiza `android/app/build.gradle.kts` para usar el keystore en builds de release.

### 3. Cambiar Application ID
Actualiza en `android/app/build.gradle.kts`:
```kotlin
applicationId = "com.tuempresa.arrendaoco"  // Cambia esto
```

### 4. Alojar Política de Privacidad
- Sube `privacy_policy.md` a un servidor web
- Obtén la URL pública
- Úsala en las configuraciones de las tiendas

### 5. Google Maps API Key
- Configura una API key de producción en Google Cloud Console
- Añade restricciones apropiadas para Android e iOS
- Actualiza la configuración en tu app

### 6. Preparar Assets para Tiendas
- Tomar screenshots de alta calidad (ver dimensiones en `store_listing.md`)
- Crear icono de alta resolución (512x512 para Android, 1024x1024 para iOS)
- Opcional: Crear video de demostración

### 7. Actualizar Información de Contacto
Edita los siguientes archivos y reemplaza los placeholders:
- `privacy_policy.md` - email, dirección, teléfono
- `terms_of_service.md` - email, dirección, teléfono
- `store_listing.md` - email, sitio web, URL de política de privacidad

## 🧪 Verificación

### Probar Build de Release

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Análisis de Código
```bash
flutter analyze
flutter test
```

## 📱 Próximos Pasos para Publicación

### Google Play Store
1. Crear cuenta de desarrollador de Google Play ($25 USD único)
2. Crear nueva aplicación en Google Play Console
3. Completar el cuestionario de clasificación de contenido
4. Subir el AAB (Android App Bundle)
5. Configurar la ficha de Play Store con screenshots y descripciones
6. Enviar para revisión

### Apple App Store
1. Crear cuenta de desarrollador de Apple ($99 USD/año)
2. Configurar App ID en Apple Developer Portal
3. Crear certificados y perfiles de aprovisionamiento
4. Crear app en App Store Connect
5. Subir el build usando Xcode o Transporter
6. Configurar la ficha de App Store con screenshots y descripciones
7. Enviar para revisión

## 📚 Recursos Útiles

- [Guía de Publicación Flutter - Android](https://docs.flutter.dev/deployment/android)
- [Guía de Publicación Flutter - iOS](https://docs.flutter.dev/deployment/ios)
- [Políticas de Google Play](https://play.google.com/about/developer-content-policy/)
- [Guías de Revisión de App Store](https://developer.apple.com/app-store/review/guidelines/)

## ⚡ Notas Importantes

- **Keystore**: NUNCA pierdas tu keystore. Sin él, no podrás actualizar tu app en Google Play.
- **Application ID**: Una vez publicado, no puedes cambiar el Application ID.
- **Versiones**: Incrementa el versionCode y versionName en `pubspec.yaml` para cada actualización.
- **Pruebas**: Siempre prueba el build de release en dispositivos reales antes de publicar.
- **Seguridad**: Asegúrate de que no haya datos sensibles, API keys, o URLs de desarrollo en el código.
