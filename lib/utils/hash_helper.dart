import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashHelper {
  /// Hashes a password using SHA-256 algorithm.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Apply SHA-256
    return digest.toString(); // Return as a hex string
  }
}
