import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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

  static const String _keyFailedAttempts = 'secure_failed_attempts';
  static const String _keyLockoutTime = 'secure_lockout_time';

  /// Sets a new PIN and enables the lock screen wrapper.
  Future<bool> setPin(String pin) async {
    final prefs = await _prefs;
    final hash = _hashPin(pin);
    // Store securely in Keychain / Keystore
    await _secureStorage.write(key: _keyPinHash, value: hash);
    return await prefs.setBool(_keyPinEnabled, true);
  }

  /// Get current lockout expiration time (returns null if not locked out)
  Future<DateTime?> getLockoutTime() async {
    final timeStr = await _secureStorage.read(key: _keyLockoutTime);
    if (timeStr == null) return null;
    final time = DateTime.tryParse(timeStr);
    if (time != null && time.isAfter(DateTime.now())) {
      return time;
    }
    // If lockout expired, clear it
    if (time != null && time.isBefore(DateTime.now())) {
      await resetLockout();
    }
    return null;
  }

  /// Register a failed PIN attempt
  Future<void> registerFailedAttempt() async {
    final attemptsStr = await _secureStorage.read(key: _keyFailedAttempts);
    int attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    attempts += 1;
    
    if (attempts >= 5) {
      // Lockout for 5 minutes
      final lockoutTime = DateTime.now().add(const Duration(minutes: 5));
      await _secureStorage.write(key: _keyLockoutTime, value: lockoutTime.toIso8601String());
    } else {
      await _secureStorage.write(key: _keyFailedAttempts, value: attempts.toString());
    }
  }

  /// Reset lockout and failed attempts counter
  Future<void> resetLockout() async {
    await _secureStorage.delete(key: _keyFailedAttempts);
    await _secureStorage.delete(key: _keyLockoutTime);
  }

  /// Verifies if the entered PIN matches the securely stored hash.
  Future<bool> verifyPin(String pin) async {
    // Prevent verification if locked out
    final lockout = await getLockoutTime();
    if (lockout != null) return false;

    // Read from secure storage
    final storedHash = await _secureStorage.read(key: _keyPinHash);
    
    // Fallback logic to migrate from SharedPreferences if updating from old version
    if (storedHash == null) {
      final prefs = await _prefs;
      final legacyHash = prefs.getString(_keyPinHash);
      if (legacyHash != null) {
        if (_hashPin(pin) == legacyHash) {
          await _secureStorage.write(key: _keyPinHash, value: legacyHash);
          prefs.remove(_keyPinHash);
          await resetLockout();
          return true;
        } else {
          await registerFailedAttempt();
          return false;
        }
      }
      return false;
    }
    
    if (_hashPin(pin) == storedHash) {
      await resetLockout();
      return true;
    } else {
      await registerFailedAttempt();
      return false;
    }
  }

  /// Disables PIN lock security and cleans up storage variables.
  Future<bool> disablePin() async {
    final prefs = await _prefs;
    await _secureStorage.delete(key: _keyPinHash);
    await prefs.remove(_keyPinHash); // Remove legacy if exists
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
