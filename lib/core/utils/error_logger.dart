import 'package:flutter/foundation.dart';

/// A centralized error logger to handle exceptions and report them.
/// In the future, this can be easily connected to Firebase Crashlytics or Sentry.
class ErrorLogger {
  static void logError(dynamic error, [StackTrace? stackTrace, String? contextMsg]) {
    // For now, we print to the debug console with clear formatting.
    // Replace with Crashlytics or external logging later.
    if (kDebugMode) {
      print('====================================');
      print('❌ APP ERROR CAUGHT');
      if (contextMsg != null) print('Context: $contextMsg');
      print('Error: $error');
      if (stackTrace != null) print('StackTrace:\n$stackTrace');
      print('====================================');
    }
  }

  static void logInfo(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }
}

/// Custom exception for expected application logic errors (e.g. Insufficient Balance)
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}
