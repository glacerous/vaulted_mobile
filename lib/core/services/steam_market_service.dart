import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SteamMarketService {
  SteamMarketService._();
  static final SteamMarketService instance = SteamMarketService._();

  /// Fetches live market price from Valve Steam Community Market
  Future<double?> fetchLiveMarketPrice(String marketHashName) async {
    try {
      final uri = Uri.parse(
        'https://steamcommunity.com/market/priceoverview/?appid=753&currency=1&market_hash_name=${Uri.encodeComponent(marketHashName)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['lowest_price'] != null) {
          final String raw = data['lowest_price'].toString().replaceAll('\$', '').trim();
          return double.tryParse(raw);
        }
      }
    } catch (e) {
      debugPrint('Live Steam Market price check notice: $e');
    }
    return null;
  }
}
