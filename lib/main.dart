// main.dart
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/login.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
// import 'package:arrendaoco/services/fcm_service.dart'; // Deleted
// import 'package:firebase_core/firebase_core.dart'; // Deleted
// import 'firebase_options.dart'; // Deleted

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://ewkythohvhdmksswsdxj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3a3l0aG9odmhkbWtzc3dzZHhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwNDQyODUsImV4cCI6MjA4MDYyMDI4NX0.gSegtK1EsXoEL88KHCLsK83EarYnVpYt5Y6oKbMm8wU',
  );
  print('✅ Supabase inicializado');

  // Inicializar servicio de notificaciones locales (seguiremos usando esto para push locales por ahora)
  try {
    await NotificacionesService.inicializar();
    print('✅ Notificaciones locales inicializadas');
  } catch (e) {
    print('⚠️ Error en notificaciones locales: $e');
  }

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
