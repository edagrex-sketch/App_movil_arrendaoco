import 'package:flutter/material.dart';
import 'arrenda_colors.dart';

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [ArrendaColors.primary, ArrendaColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF9E2A2B), Color(0xFFBD3C3E)], // Vino a Rojo Suave (Premium)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Colors.white, ArrendaColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
