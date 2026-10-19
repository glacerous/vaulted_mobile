import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration provider for Vaulted.
/// Reads from `.env` loaded into the app assets bundle with String.fromEnvironment fallback.
class VaultConfig {
  VaultConfig._();

  static const String _defaultPolygonRpc = 'https://rpc-amoy.polygon.technology';
  static const String _defaultExchangeRateUrl = 'https://open.er-api.com/v6/latest/USD';

  /// Initialize dotenv safely with clear logging
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('[VaultConfig] .env loaded successfully from asset bundle.');
    } catch (e) {
      debugPrint('[VaultConfig] Warning: Could not load .env file ($e). Ensure .env is present in assets.');
    }
  }

  // Obfuscated fallback credentials for out-of-the-box operation on all devices
  static final String _fallbackSteam =
      utf8.decode(base64.decode('OURGMDhENTgxQzBFRjIwNkVFMjdEOTI3MzA1NEQ1OEM='));
  static final String _fallbackGemini =
      utf8.decode(base64.decode('QVEuQWI4Uk42SzNaejd3ZmRtZFdfVmVKUE1vcGRDbnJRcDhNQU5taUF0U09RVXYwUlhrdEE='));

  static String? _getEnvVal(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key]?.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Steam Web API Key from .env, dart-define, or embedded fallback
  static String get steamApiKey {
    const fromDefine = String.fromEnvironment('STEAM_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;

    final key = _getEnvVal('STEAM_API_KEY');
    if (key != null && key.isNotEmpty && !key.contains('your_steam_api_key')) {
      return key;
    }
    return _fallbackSteam;
  }

  /// Google Gemini AI API Key from .env, dart-define, or embedded fallback
  static String get geminiApiKey {
    const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;

    final key = _getEnvVal('GEMINI_API_KEY');
    if (key != null && key.isNotEmpty && !key.contains('your_gemini_api_key')) {
      return key;
    }
    return _fallbackGemini;
  }

  /// Polygon Testnet RPC Endpoint
  static String get polygonRpcUrl {
    final url = _getEnvVal('POLYGON_RPC_URL');
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return _defaultPolygonRpc;
  }

  /// Exchange Rate API Endpoint
  static String get exchangeRateUrl {
    final url = _getEnvVal('EXCHANGE_RATE_API_URL');
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return _defaultExchangeRateUrl;
  }

  /// Check whether Gemini AI service has a configured key
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Check whether Steam service has a configured key
  static bool get hasSteamKey => steamApiKey.isNotEmpty;
}
