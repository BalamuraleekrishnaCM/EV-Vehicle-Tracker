import 'package:flutter/material.dart';

/// Minimal, high-contrast EV-friendly visual system.
abstract final class EvPalette {
  static const green = Color(0xFF0AAF47);
  static const deepGreen = Color(0xFF087C39);
  static const background = Color(0xFFF3FAF7);
  static const ink = Color(0xFF10241B);
  static const secondary = Color(0xFF52675C);
}

ThemeData buildEvTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: EvPalette.green,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: EvPalette.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: EvPalette.background,
      foregroundColor: EvPalette.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.symmetric(vertical: 7),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFD9F8E2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
