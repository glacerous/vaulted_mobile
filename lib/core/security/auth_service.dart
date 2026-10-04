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
      if (kIsWeb) {
        _webSessionUser = username;
      } else {
        await _storage.write(key: _sessionKey, value: username);
        await _storage.write(key: _userNameKey, value: user['full_name'] as String? ?? username);
      }
      return true;
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
      final isAvailable = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
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
