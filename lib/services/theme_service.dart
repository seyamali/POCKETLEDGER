import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketledger/app/theme.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _keyThemeMode = 'theme_mode_dark';
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Initializes the saved theme mode from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_keyThemeMode) ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    AppColors.isDark = isDark;
  }

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  /// Toggles and saves the selected theme mode state.
  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, isDark);
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    AppColors.isDark = isDark;
  }
}
