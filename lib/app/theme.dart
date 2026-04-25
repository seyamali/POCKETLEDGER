import 'package:flutter/material.dart';

class AppColors {
  // Primary Background: Deep Midnight Navy for Scaffolds and Splash.
  static const Color primaryBackground = Color(0xFF0B1E2B);
  
  // Brand Primary: Forest Green for headers and main wallet UI.
  static const Color brandPrimary = Color(0xFF2D6A4F);
  
  // Accent / Action: Sea-foam Green for buttons and progress bars.
  static const Color accentAction = Color(0xFF52B788);
  
  // Currency Highlight: Taka Gold for balance and premium features.
  static const Color currencyHighlight = Color(0xFFFFB703);
  
  // Primary Text: Off-white for high readability on dark backgrounds.
  static const Color primaryText = Color(0xFFF8F9FA);
  
  // Secondary Text: Slate Gray for taglines and timestamps.
  static const Color secondaryText = Color(0xFF6C757D);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brandPrimary,
    brightness: Brightness.dark,
    primary: AppColors.brandPrimary,
    secondary: AppColors.accentAction,
    surface: AppColors.primaryBackground,
    error: Colors.redAccent,
  ),
  scaffoldBackgroundColor: AppColors.primaryBackground,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.primaryText),
    bodyMedium: TextStyle(color: AppColors.primaryText),
    displayLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
  ),
);
