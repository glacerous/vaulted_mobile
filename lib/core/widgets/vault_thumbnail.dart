import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/image_utils.dart';

/// Renders luxury asset thumbnails across VAULTED.
///
/// Seamlessly handles:
/// 1. Local device photo files (from camera/OCR capture)
/// 2. Remote CDN images (Steam Community, cloud storage)
/// 3. High-luxury titanium fallback badges tailored by category and asset name
///    instead of generic boilerplate placeholders.
class VaultThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  final String? name;
  final double width;
  final double height;
  final double borderRadius;

  const VaultThumbnail({
    super.key,
    this.imageUrl,
    this.category,
    this.name,
    this.width = 44,
    this.height = 44,
    this.borderRadius = 10,
  });

  static const String _boilerplateMacbook =
      'https://images.unsplash.com/photo-1517336714731-489689fd1ca8';

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl?.trim();

    // 1. Check for valid local image file (camera / scanner receipt)
    if (cleanUrl != null && cleanUrl.isNotEmpty && !kIsWeb) {
      if (cleanUrl.startsWith('/') ||
          cleanUrl.startsWith('file://') ||
          (cleanUrl.length > 2 && cleanUrl[1] == ':')) {
        final filePath = cleanUrl.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCategoryBadge(),
            ),
          );
        }
      }
    }

    // 2. Check for real remote network image (ignoring hardcoded generic boilerplate)
    final isBoilerplate = cleanUrl != null &&
        cleanUrl.startsWith(_boilerplateMacbook);

    if (cleanUrl != null &&
        cleanUrl.isNotEmpty &&
        (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) &&
        !isBoilerplate) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          vaultImageUrl(cleanUrl),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildCategoryBadge(),
        ),
      );
    }

    // 3. Ultra-luxury Category Vector Badge
    return _buildCategoryBadge();
  }

  Widget _buildCategoryBadge() {
    final iconData = _resolveIcon();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: VaultColors.cardHover,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: VaultColors.hairline,
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.cardHover,
            VaultColors.card,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: width * 0.48,
        color: VaultColors.accent,
      ),
    );
  }

  IconData _resolveIcon() {
    final combined = '${category ?? ''} ${name ?? ''}'.toLowerCase();

    if (combined.contains('watch') ||
        combined.contains('horology') ||
        combined.contains('rolex') ||
        combined.contains('omega') ||
        combined.contains('cartier')) {
      return Icons.watch_rounded;
    }

    if (combined.contains('camera') ||
        combined.contains('lens') ||
        combined.contains('leica') ||
        combined.contains('sony a') ||
        combined.contains('fujifilm') ||
        combined.contains('canon')) {
      return Icons.camera_alt_rounded;
    }

    if (combined.contains('laptop') ||
        combined.contains('macbook') ||
        combined.contains('thinkpad') ||
        combined.contains('notebook') ||
        combined.contains('asus rog') ||
        combined.contains('zenbook')) {
      return Icons.laptop_mac_rounded;
    }

    if (combined.contains('phone') ||
        combined.contains('iphone') ||
        combined.contains('galaxy') ||
        combined.contains('pixel') ||
        combined.contains('smartphone')) {
      return Icons.phone_iphone_rounded;
    }

    if (combined.contains('audio') ||
        combined.contains('headphone') ||
        combined.contains('earphone') ||
        combined.contains('airpods') ||
        combined.contains('sennheiser') ||
        combined.contains('sony wh')) {
      return Icons.headphones_rounded;
    }

    if (combined.contains('gpu') ||
        combined.contains('graphics') ||
        combined.contains('rtx') ||
        combined.contains('processor') ||
        combined.contains('hardware') ||
        combined.contains('cpu')) {
      return Icons.memory_rounded;
    }

    if (combined.contains('tablet') ||
        combined.contains('ipad') ||
        combined.contains('surface')) {
      return Icons.tablet_mac_rounded;
    }

    if (combined.contains('cs2') ||
        combined.contains('steam') ||
        combined.contains('game') ||
        combined.contains('gaming') ||
        combined.contains('skin') ||
        combined.contains('knife') ||
        combined.contains('case')) {
      return Icons.sports_esports_rounded;
    }

    if (combined.contains('bag') ||
        combined.contains('leather') ||
        combined.contains('wallet') ||
        combined.contains('luxury')) {
      return Icons.shopping_bag_outlined;
    }

    return Icons.devices_other_rounded;
  }
}
