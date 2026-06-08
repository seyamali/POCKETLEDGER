import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = false;

  // 💎 Premium Re-Design Palette (Dynamic getters for Dark Mode support)
  static Color get primaryGreen => isDark ? const Color(0xFF52B788) : const Color(0xFF005B41);
  static Color get accentGold => const Color(0xFFFFB800);
  static Color get background => isDark ? const Color(0xFF0F1715) : Colors.white;

  // Page & Surface Backgrounds
  /// The grey page background used in most screens (e.g. 0xFFF4F6F5 in light)
  static Color get pageBackground => isDark ? const Color(0xFF0F1715) : const Color(0xFFF4F6F5);
  /// Pure white cards in light, dark card in dark
  static Color get cardWhite => isDark ? const Color(0xFF16201D) : Colors.white;
  /// Subtle tinted surface (e.g. 0xFFF8FAF9 in light)
  static Color get surfaceLight => isDark ? const Color(0xFF16201D) : const Color(0xFFF8FAF9);

  // Text Colors
  static Color get textBlack => isDark ? Colors.white : const Color(0xFF1A1A1A);
  static Color get textGrey => isDark ? const Color(0xFF9EAEAA) : const Color(0xFF757575);

  // Borders
  static Color get borderLight => isDark ? const Color(0xFF283A35) : const Color(0xFFEEEEEE);

  // Feedback
  static Color get error => const Color(0xFFE53935);
  static Color get success => const Color(0xFF00A859);

  // Legacy mappings
  static Color get brandPrimary => primaryGreen;
  static Color get accentAction => accentGold;
  static Color get primaryBackground => background;
  static Color get cardBackground => cardWhite;
  static Color get primaryText => textBlack;
  static Color get secondaryText => textGrey;
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF005B41),
    secondary: const Color(0xFFFFB800),
    surface: Colors.white,
    error: const Color(0xFFE53935),
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F6F5),
  fontFamily: 'Outfit',
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 32),
    headlineMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 20),
    bodyLarge: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16),
    bodyMedium: TextStyle(color: Color(0xFF757575), fontSize: 14),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF4F6F5),
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
    titleTextStyle: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF52B788),
    secondary: Color(0xFFFFB800),
    surface: Color(0xFF16201D),
    error: Color(0xFFE53935),
  ),
  scaffoldBackgroundColor: const Color(0xFF0F1715),
  fontFamily: 'Outfit',
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 32),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Color(0xFF9EAEAA), fontSize: 14),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F1715),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
  ),
);
