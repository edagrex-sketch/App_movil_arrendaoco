// main.dart
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/login.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Descomentar una vez generado con `flutterfire configure`
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificacionesService.firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    // Si tienes firebase_options.dart:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Si NO tienes firebase_options.dart aún, esto funcionará a medias o fallará
    // hasta que configures el proyecto en consola:
    await Firebase.initializeApp();
    debugPrint('✅ Firebase inicializado');

    // Configurar manejador en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurar FCM (Permisos y Listeners)
    await NotificacionesService.configurarFCM();
  } catch (e) {
    debugPrint('⚠️ Error inicializando Firebase (¿Falta configuración?): $e');
  }

  // Inicializar servicio de notificaciones locales (seguiremos usando esto para push locales por ahora)
  try {
    await NotificacionesService.inicializar();
    debugPrint('✅ Notificaciones locales inicializadas');
  } catch (e) {
    debugPrint('⚠️ Error en notificaciones locales: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ArrendaOco',
          theme: MiTema.lightTheme(context),
          darkTheme: MiTema.darkTheme(context),
          themeMode: ThemeManager().themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
