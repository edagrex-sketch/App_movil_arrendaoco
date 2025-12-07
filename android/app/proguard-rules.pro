# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# SQLite - CRÍTICO para que funcione el registro
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-keep class android.database.** { *; }
-keep class android.database.sqlite.** { *; }
-dontwarn org.sqlite.**

# Sqflite plugin
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Gson (si se usa para JSON)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# Mantener clases de modelo de datos
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Mantener información de línea para debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# No ofuscar clases que usan reflexión
-keepattributes InnerClasses
-keep class **.R$* {
    <fields>;
}
