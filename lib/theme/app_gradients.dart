import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF003049), Color(0xFF669BBC)], // Azul -> Celeste
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF780000), Color(0xFFC1121F)], // Vino -> Rojo
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFDF0D5)], // Blanco -> Crema (Subtle)
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
