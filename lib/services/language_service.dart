import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _keyLanguage = 'app_language';
  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

  /// Initializes the saved language from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_keyLanguage) ?? 'en';
    languageNotifier.value = lang;
  }

  String get currentLanguage => languageNotifier.value;
  bool get isBengali => currentLanguage == 'bn';

  /// Toggles and saves the selected language state.
  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, langCode);
    languageNotifier.value = langCode;
  }
}
