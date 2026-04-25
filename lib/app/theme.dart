import 'package:flutter/material.dart';

class AppColors {
  // 💎 Premium Re-Design Palette
  static const Color primaryGreen = Color(0xFF005B41);  // Deep Premium Green
  static const Color accentGold = Color(0xFFFFB800);   // Vibrant QuickPay Gold
  static const Color background = Colors.white;        // Pure White Background
  
  // Text Colors
  static const Color textBlack = Color(0xFF1A1A1A);    // Crisp Bold Black
  static const Color textGrey = Color(0xFF757575);     // Soft Subtle Grey
  
  // Cards & Surfaces
  static const Color surfaceLight = Color(0xFFF8FAF9); // Ultra-light Mint/Grey
  static const Color borderLight = Color(0xFFEEEEEE);  // Subtle Borders
  
  // Feedback
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF00A859);

  // Legacy mappings
  static const Color brandPrimary = primaryGreen;
  static const Color accentAction = accentGold;
  static const Color primaryBackground = background;
  static const Color cardBackground = Colors.white;
  static const Color primaryText = textBlack;
  static const Color secondaryText = textGrey;
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.accentGold,
    surface: AppColors.background,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'Outfit', // High-end Sans-serif
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.w700, fontSize: 32),
    headlineMedium: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.w600, fontSize: 20),
    bodyLarge: TextStyle(color: AppColors.textBlack, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.textGrey, fontSize: 14),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textBlack,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.textBlack),
    titleTextStyle: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.bold, fontSize: 18),
  ),
);
