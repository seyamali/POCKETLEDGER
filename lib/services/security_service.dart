import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const String _keyPinEnabled = 'secure_pin_enabled';
  static const String _keyPinHash = 'secure_pin_hash';
  static const String _keyBiometricEnabled = 'secure_biometric_enabled';
  // Standard hardcoded salt to append to user input before hashing
  static const String _salt = 'pocketledger_salt_2026';

  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Checks if the local PIN security lock is active.
  Future<bool> isPinEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyPinEnabled) ?? false;
  }

  /// Hashes the raw PIN string using SHA-256 with salt.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sets a new PIN and enables the lock screen wrapper.
  Future<bool> setPin(String pin) async {
    final prefs = await _prefs;
    final hash = _hashPin(pin);
    await prefs.setString(_keyPinHash, hash);
    return await prefs.setBool(_keyPinEnabled, true);
  }

  /// Verifies if the entered PIN matches the securely stored hash.
  Future<bool> verifyPin(String pin) async {
    final prefs = await _prefs;
    final storedHash = prefs.getString(_keyPinHash);
    if (storedHash == null) return false;
    return _hashPin(pin) == storedHash;
  }

  /// Disables PIN lock security and cleans up storage variables.
  Future<bool> disablePin() async {
    final prefs = await _prefs;
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keyBiometricEnabled);
    return await prefs.setBool(_keyPinEnabled, false);
  }

  /// Checks if biometrics authentication is enabled by the user.
  Future<bool> isBiometricEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Sets whether biometrics authentication is enabled/disabled.
  Future<bool> setBiometricEnabled(bool enabled) async {
    final prefs = await _prefs;
    return await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Checks if the device has biometric capabilities and enrolled credentials.
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Triggers Face ID/Fingerprint verification prompt.
  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock PocketLedger',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } catch (_) {
      return false;
    }
  }
}
