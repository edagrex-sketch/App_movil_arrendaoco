import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'arrenda_colors.dart';

class MiTema {
  static Color get azul => ArrendaColors.primary;
  static Color get celeste => ArrendaColors.accent;
  static Color get crema => ArrendaColors.background;
  static Color get vino => ArrendaColors.error;
  static Color get rojo => const Color(0xFF9E2A2B);
  static Color get blanco => Colors.white;
  static Color get negro => ArrendaColors.foreground;
  static Color get verde => const Color(0xFF2E7D32);
  static Color get oro => ArrendaColors.gold;

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: ArrendaColors.primary,
        primary: ArrendaColors.primary,
        secondary: ArrendaColors.accent,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: ArrendaColors.error,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: Colors.white.withOpacity(0.9),
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
