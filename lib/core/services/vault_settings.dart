import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton manager for user preferences and hardware/security toggles in VAULTED.
class VaultSettings {
  static final VaultSettings instance = VaultSettings._init();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  VaultSettings._init();

  // Settings keys
  static const String _kBiometrics = 'vault_setting_biometrics';
  static const String _kShakeLock = 'vault_setting_shake_lock';
  static const String _kPrivacyMask = 'vault_setting_privacy_mask';
  static const String _kHaptics = 'vault_setting_haptics';
  static const String _kNotifications = 'vault_setting_notifications';
  static const String _kCurrency = 'vault_setting_currency';

  // In-memory state cache
  bool _biometricsEnabled = true;
  bool _shakeLockEnabled = true;
  bool _privacyMaskEnabled = false;
  bool _hapticsEnabled = true;
  bool _notificationsEnabled = true;
  String _currency = 'USD';
  bool _initialized = false;

  bool get biometricsEnabled => _biometricsEnabled;
  bool get shakeLockEnabled => _shakeLockEnabled;
  bool get privacyMaskEnabled => _privacyMaskEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  String get currency => _currency;

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (!kIsWeb) {
        final bio = await _storage.read(key: _kBiometrics);
        if (bio != null) _biometricsEnabled = bio == 'true';

        final shake = await _storage.read(key: _kShakeLock);
        if (shake != null) _shakeLockEnabled = shake == 'true';

        final mask = await _storage.read(key: _kPrivacyMask);
        if (mask != null) _privacyMaskEnabled = mask == 'true';

        final hap = await _storage.read(key: _kHaptics);
        if (hap != null) _hapticsEnabled = hap == 'true';

        final notif = await _storage.read(key: _kNotifications);
        if (notif != null) _notificationsEnabled = notif == 'true';

        final cur = await _storage.read(key: _kCurrency);
        if (cur != null && cur.isNotEmpty) _currency = cur;
      }
    } catch (e) {
      debugPrint('[VaultSettings] Load error: $e');
    }
    _initialized = true;
  }

  Future<void> setBiometrics(bool value) async {
    _biometricsEnabled = value;
    _notify();
    if (!kIsWeb) await _storage.write(key: _kBiometrics, value: value.toString());
  }

  Future<void> setShakeLock(bool value) async {
    _shakeLockEnabled = value;
    _notify();
    if (!kIsWeb) await _storage.write(key: _kShakeLock, value: value.toString());
  }

  Future<void> setPrivacyMask(bool value) async {
    _privacyMaskEnabled = value;
    _notify();
    if (!kIsWeb) await _storage.write(key: _kPrivacyMask, value: value.toString());
  }

  Future<void> setHaptics(bool value) async {
    _hapticsEnabled = value;
    _notify();
    if (!kIsWeb) await _storage.write(key: _kHaptics, value: value.toString());
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    _notify();
    if (!kIsWeb) await _storage.write(key: _kNotifications, value: value.toString());
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    _notify();
    if (!kIsWeb) await _storage.write(key: _kCurrency, value: value);
  }

  void _notify() {
    changeNotifier.value++;
  }
}
