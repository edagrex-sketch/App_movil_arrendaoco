// main.dart
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';  
import 'package:arrendaoco/view/login.dart';  
void main() {
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
