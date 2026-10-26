import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/vault_config.dart';
import '../database/database_helper.dart';
import '../services/supabase_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _activeSessionUser;
  String? _activeFullName;

  AuthService._init();

  static const String _sessionKey = 'vaulted_user_session';
  static const String _userNameKey = 'vaulted_user_name';

  Future<bool> login(String username, String password) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final hash = sha256.convert(utf8.encode(cleanPass)).toString();

    // 1. Online Database Authentication (Supabase PostgreSQL vault_users)
    if (VaultConfig.hasSupabase) {
      try {
        final onlineUser = await SupabaseService.instance
            .authenticateUserOnline(username: cleanUser, passwordHash: hash)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        if (onlineUser != null) {
          _activeSessionUser = cleanUser;
          _activeFullName = onlineUser['full_name'] as String? ?? cleanUser;

          // Cache in local SQLite database for offline-first resilience
          await DatabaseHelper.instance.cacheUser(
            cleanUser,
            hash,
            _activeFullName!,
          );

          if (!kIsWeb) {
            try {
              await _storage.write(key: _sessionKey, value: cleanUser);
              await _storage.write(key: _userNameKey, value: _activeFullName);
            } catch (_) {}
          }
          return true;
        }
      } catch (e) {
        debugPrint('[AuthService] Online auth fallback: $e');
      }
    }

    // 2. Local Database Authentication (SQLite / In-Memory cache)
    try {
      final user = await DatabaseHelper.instance
          .authenticateUser(cleanUser, cleanPass)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (user != null) {
        _activeSessionUser = cleanUser;
        _activeFullName = user['full_name'] as String? ?? cleanUser;
        if (!kIsWeb) {
          try {
            await _storage
                .write(key: _sessionKey, value: cleanUser)
                .timeout(const Duration(seconds: 2));
            await _storage
                .write(key: _userNameKey, value: _activeFullName)
                .timeout(const Duration(seconds: 2));
          } catch (e) {
            debugPrint('[AuthService] Secure storage write notice: $e');
          }
        }
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Login notice: $e');
    }

    // 3. Built-in hardcoded fallback for default demo user
    if (cleanUser.toLowerCase() == 'azzaky' && cleanPass == 'admin123') {
      _activeSessionUser = cleanUser;
      _activeFullName = 'Azzaky Raihan';
      return true;
    }

    return false;
  }

  Future<bool> register(String username, String password, {String? fullName}) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final displayName = (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim() : cleanUser;
    final hash = sha256.convert(utf8.encode(cleanPass)).toString();

    // 1. Register Online in Supabase PostgreSQL if configured
    if (VaultConfig.hasSupabase) {
      try {
        final onlineRes = await SupabaseService.instance
            .registerUserOnline(
              username: cleanUser,
              passwordHash: hash,
              fullName: displayName,
            )
            .timeout(const Duration(seconds: 5), onTimeout: () => {'success': false, 'message': 'timeout'});

        if (onlineRes['isDuplicate'] == true) {
          return false; // Username already taken in cloud
        }
      } catch (e) {
        debugPrint('[AuthService] Online register notice: $e');
      }
    }

    // 2. Register in Local SQLite database
    try {
      final success = await DatabaseHelper.instance
          .registerUser(cleanUser, cleanPass, fullName: displayName)
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (success) {
        return await login(cleanUser, cleanPass);
      }
    } catch (e) {
      debugPrint('[AuthService] Register notice: $e');
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) {
      // Simulate successful biometric on web browser
      _activeSessionUser = 'azzaky';
      _activeFullName = 'Azzaky Raihan';
      return true;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      final success = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (success) {
        String lastUser = 'azzaky';
        String lastName = 'Azzaky Raihan';
        try {
          final existing = await _storage
              .read(key: _sessionKey)
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
          final existingName = await _storage
              .read(key: _userNameKey)
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
          if (existing != null && existing.isNotEmpty) {
            lastUser = existing;
            lastName = existingName ?? existing;
          } else {
            await _storage
                .write(key: _sessionKey, value: lastUser)
                .timeout(const Duration(seconds: 2));
            await _storage
                .write(key: _userNameKey, value: lastName)
                .timeout(const Duration(seconds: 2));
          }
        } catch (_) {}
        _activeSessionUser = lastUser;
        _activeFullName = lastName;
        return true;
      }
      return success;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    if (_activeSessionUser != null && _activeSessionUser!.isNotEmpty) return true;
    if (kIsWeb) return false;
    try {
      final session = await _storage
          .read(key: _sessionKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (session != null && session.isNotEmpty) {
        _activeSessionUser = session;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String? get activeSessionUser => _activeSessionUser;
  String? get activeFullName => _activeFullName;

  Future<String> getCurrentUser() async {
    if (_activeSessionUser != null && _activeSessionUser!.isNotEmpty) {
      return _activeSessionUser!;
    }
    if (kIsWeb) return 'azzaky';
    try {
      final user = await _storage
          .read(key: _sessionKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (user != null && user.isNotEmpty) {
        _activeSessionUser = user;
        return user;
      }
      return 'azzaky';
    } catch (_) {
      return 'azzaky';
    }
  }

  Future<String> getCurrentFullName() async {
    if (_activeFullName != null && _activeFullName!.isNotEmpty) {
      return _activeFullName!;
    }
    if (kIsWeb) return _activeSessionUser ?? 'Azzaky Raihan';
    try {
      final name = await _storage
          .read(key: _userNameKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (name != null && name.isNotEmpty) {
        _activeFullName = name;
        return name;
      }
    } catch (_) {}
    return _activeSessionUser ?? 'Azzaky Raihan';
  }

  Future<void> logout() async {
    _activeSessionUser = null;
    _activeFullName = null;
    if (!kIsWeb) {
      try {
        await _storage.delete(key: _sessionKey).timeout(const Duration(seconds: 2));
        await _storage.delete(key: _userNameKey).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  /// Update profile data in DB and sync in-memory name / secure storage.
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_activeSessionUser == null) return false;
    final ok = await DatabaseHelper.instance.updateUserProfile(
      _activeSessionUser!,
      updates,
    );
    if (ok && updates.containsKey('full_name')) {
      _activeFullName = updates['full_name'] as String?;
      if (!kIsWeb) {
        try {
          await _storage.write(key: _userNameKey, value: _activeFullName);
        } catch (_) {}
      }
    }
    return ok;
  }
}
