import 'package:flutter/material.dart';

class ArrendaColors {
  /// **Fondo General de la App.**
  /// Se usa en Scaffold backgroundColor para dar calidez y un look limpio.
  static const Color background = Color(0xFFF5F1E8); // Crema Suave

  /// **Color de Marca / Acción Principal.**
  /// Se usa en Header del Appbar, botones primarios y textos de importancia alta.
  static const Color primary = Color(0xFF1F3A5F); // Azul Marino

  /// **Color de Énfasis / Interacción.**
  /// Se usa en iconos activos, bordes de inputs en foco y gradientes de botones.
  static const Color accent = Color(0xFF2E5E8C); // Azul Vibrante

  /// **Color de Texto Base.**
  /// Se usa para el cuerpo del texto y descripciones generales.
  static const Color foreground = Color(0xFF1F3A5F);

  /// **Color de Categoría / VIP.**
  /// Se usa para iconos de "Favoritos", medallas (badges) de Propietarios VIP o detalles de lujo.
  static const Color gold = Color(0xFFD4AF37); // Oro Luxury

  /// **Capas de Cristal.**
  /// Se usa como fondo de tarjetas (Cards) envueltas en BackdropFilter.
  static Color glassBg = Colors.white.withOpacity(0.15);

  /// **Líneas de Guía.**
  /// Se usa solo para los bordes finos de las tarjetas de cristal.
  static Color glassBorder = Colors.white.withOpacity(0.3);

  /// **Alertas / Peligro.**
  /// Se usa para el botón de "Cerrar Sesión" o errores de validación.
  static const Color error = Color(0xFF9E2A2B);
}
