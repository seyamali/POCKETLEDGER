import 'package:flutter/material.dart';
import 'package:pocketledger/features/accounts/accounts_screen.dart';
import 'package:pocketledger/features/accounts/add_account_screen.dart';
import 'package:pocketledger/features/auth/login_screen.dart';
import 'package:pocketledger/features/auth/signup_screen.dart';
import 'package:pocketledger/features/auth/splash_screen.dart';
import 'package:pocketledger/features/profile/profile_screen.dart';
import 'package:pocketledger/app/main_nav_wrapper.dart';
import 'package:pocketledger/features/transactions/add_transaction_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String accounts = '/accounts';
  static const String addAccount = '/add-account';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String addTransaction = '/add-transaction';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    accounts: (context) => const AccountsScreen(),
    addAccount: (context) => const AddAccountScreen(),
    dashboard: (context) => const MainNavWrapper(),
    profile: (context) => const ProfileScreen(),
    addTransaction: (context) => const AddTransactionScreen(),
  };
}
