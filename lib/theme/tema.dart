import 'package:flutter/material.dart';

class MiTema {
//PALETA DE COLORES:
  static Color vino = const Color.fromARGB(255, 120, 0, 0);
  static Color rojo = const Color.fromARGB(255, 193, 18, 31);
  static Color crema = const Color.fromARGB(255, 253, 240, 213);
  static Color azul = const Color.fromARGB(255, 0, 48, 73);
  static Color celeste = const Color.fromARGB(255, 102, 155, 188);
  static Color blanco = const Color.fromARGB(255, 255, 255, 255);
  static Color negro = const Color.fromARGB(255, 0, 0, 0);
  

  static ThemeData temaApp(BuildContext context) {
    return ThemeData(
        colorScheme: _esquemaColores(context), appBarTheme: _temaAppBar());
  }

  static ColorScheme _esquemaColores(BuildContext context) {
    return ColorScheme(
        brightness: MediaQuery.platformBrightnessOf(context),
        primary: blanco,
        onPrimary: azul,
        secondary: vino,
        onSecondary: vino,
        error: Colors.red,
        onError: Colors.white,
        surface: blanco,
        onSurface: vino);
  }

  static AppBarTheme _temaAppBar() {
    return AppBarTheme(backgroundColor: blanco, foregroundColor: azul);
  }
}