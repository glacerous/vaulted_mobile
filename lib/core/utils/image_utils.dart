import 'package:flutter/foundation.dart';

/// Ensures images (especially Steam CDN images without CORS headers)
/// render smoothly in Flutter Web (CanvasKit / HTML) without canvas tainting.
String vaultImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return 'https://community.cloudflare.steamstatic.com/public/images/apps/753/default.png';
  }
  final clean = url.trim();
  if (kIsWeb && (clean.contains('steamstatic.com') || clean.contains('steamcommunity.com'))) {
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(clean)}';
  }
  return clean;
}
