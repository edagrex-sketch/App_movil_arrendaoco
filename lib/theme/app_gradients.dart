import 'package:flutter/material.dart';
import 'arrenda_colors.dart';

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [ArrendaColors.primary, ArrendaColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [ArrendaColors.accent, ArrendaColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Colors.white, ArrendaColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
