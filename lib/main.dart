// main.dart
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/login.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de notificaciones
  await NotificacionesService.inicializar();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArrendaOco',
      theme: MiTema.temaApp(context),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}
