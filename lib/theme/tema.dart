import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'arrenda_colors.dart';

class MiTema {
  // Aliases para la nueva paleta de colores LUXURY
  static Color get azul => ArrendaColors.primary;
  static Color get celeste => ArrendaColors.accent;
  static Color get crema => ArrendaColors.background;
  static Color get vino => ArrendaColors.error;
  static Color get rojo => const Color(0xFF9E2A2B);
  static Color get blanco => Colors.white;
  static Color get negro => ArrendaColors.foreground;
  static Color get verde => const Color(0xFF2E7D32);
  static Color get oro => ArrendaColors.gold;

  static ThemeData temaApp(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ArrendaColors.primary,
        primary: ArrendaColors.primary,
        secondary: ArrendaColors.accent,
        surface: Colors.white,
        background: ArrendaColors.background,
        error: ArrendaColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ArrendaColors.foreground,
        onBackground: ArrendaColors.foreground,
      ),
      scaffoldBackgroundColor: ArrendaColors.background,
      textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: ArrendaColors.foreground,
        displayColor: ArrendaColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: ArrendaColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: ArrendaColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ArrendaColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ArrendaColors.accent, width: 1),
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
}
