import 'package:flutter/material.dart';
import 'package:pocketledger/features/accounts/accounts_screen.dart';
import 'package:pocketledger/features/accounts/add_account_screen.dart';
import 'package:pocketledger/features/auth/login_screen.dart';
import 'package:pocketledger/features/auth/signup_screen.dart';
import 'package:pocketledger/features/auth/splash_screen.dart';
import 'package:pocketledger/features/profile/profile_screen.dart';
import 'package:pocketledger/app/main_nav_wrapper.dart';
import 'package:pocketledger/features/transactions/add_transaction_screen.dart';

import 'package:pocketledger/features/categories/category_manager_screen.dart';
import 'package:pocketledger/features/credit_cards/credit_cards_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String accounts = '/accounts';
  static const String addAccount = '/add-account';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String addTransaction = '/add-transaction';
  static const String categories = '/categories';
  static const String creditCards = '/credit-cards';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    accounts: (context) => const AccountsScreen(),
    addAccount: (context) => const AddAccountScreen(),
    dashboard: (context) => const MainNavWrapper(),
    profile: (context) => const ProfileScreen(),
    addTransaction: (context) => const AddTransactionScreen(),
    categories: (context) => const CategoryManagerScreen(),
    creditCards: (context) => const CreditCardsScreen(),
  };
}
