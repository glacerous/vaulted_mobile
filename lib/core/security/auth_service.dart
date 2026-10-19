import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../database/database_helper.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _webSessionUser;

  AuthService._init();

  static const String _sessionKey = 'vaulted_user_session';
  static const String _userNameKey = 'vaulted_user_name';

  Future<bool> login(String username, String password) async {
    final user = await DatabaseHelper.instance.authenticateUser(username, password);
    if (user != null) {
      _webSessionUser = username;
      if (!kIsWeb) {
        try {
          await _storage.write(key: _sessionKey, value: username);
          await _storage.write(key: _userNameKey, value: user['full_name'] as String? ?? username);
        } catch (e) {
          debugPrint('Secure storage write notice: $e');
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password, {String? fullName}) async {
    final success = await DatabaseHelper.instance.registerUser(username, password, fullName: fullName);
    if (success) {
      return await login(username, password);
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) {
      // Simulate successful biometric on web browser
      _webSessionUser = 'azzaky';
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
        // Ensure active session key is saved upon biometric success
        final existing = await _storage.read(key: _sessionKey);
        if (existing == null || existing.isEmpty) {
          await _storage.write(key: _sessionKey, value: 'azzaky');
          await _storage.write(key: _userNameKey, value: 'Azzaky Raihan');
        }
      }
      return success;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    if (kIsWeb) return _webSessionUser != null;
    try {
      final session = await _storage.read(key: _sessionKey);
      return session != null && session.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> getCurrentUser() async {
    if (kIsWeb) return _webSessionUser ?? 'azzaky';
    final user = await _storage.read(key: _sessionKey);
    return user ?? 'azzaky';
  }

  Future<void> logout() async {
    if (kIsWeb) {
      _webSessionUser = null;
    } else {
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _userNameKey);
    }
  }
}
