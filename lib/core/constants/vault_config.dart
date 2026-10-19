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

  /// Steam Web API Key from .env or dart-define
  static String get steamApiKey {
    const fromDefine = String.fromEnvironment('STEAM_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;

    final key = dotenv.env['STEAM_API_KEY']?.trim();
    if (key != null && key.isNotEmpty && !key.contains('your_steam_api_key')) {
      return key;
    }
    return '';
  }

  /// Google Gemini AI API Key from .env or dart-define
  static String get geminiApiKey {
    const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;

    final key = dotenv.env['GEMINI_API_KEY']?.trim();
    if (key != null && key.isNotEmpty && !key.contains('your_gemini_api_key')) {
      return key;
    }
    return '';
  }

  /// Polygon Testnet RPC Endpoint
  static String get polygonRpcUrl {
    final url = dotenv.env['POLYGON_RPC_URL']?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return _defaultPolygonRpc;
  }

  /// Exchange Rate API Endpoint
  static String get exchangeRateUrl {
    final url = dotenv.env['EXCHANGE_RATE_API_URL']?.trim();
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
