import 'package:flutter/material.dart';
import 'package:pocketledger/features/auth/login_screen.dart';
import 'package:pocketledger/features/auth/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
  };
}
