import 'package:flutter/material.dart';

/// Clean luxury light-mode design system for VAULTED
/// Inspired by Emil Kowalski principles and the warm, airy Oyenza mobile aesthetic.
class VaultColors {
  // Canvas & Surfaces (Warm Porcelain & Crisp White)
  static const Color background = Color(0xFFFAF9F6); // Warm porcelain canvas
  static const Color card = Color(0xFFFFFFFF);       // Crisp white surface
  static const Color cardHover = Color(0xFFF4F3EE);  // Subtle hover/press tint
  static const Color hairline = Color(0xFFEBE8E0);   // Feather-light hairline divider

  // Typography & Inks
  static const Color ink = Color(0xFF141413);        // Deep rich black primary ink
  static const Color ink2 = Color(0xFF73716A);       // Secondary graphite ink
  static const Color ink3 = Color(0xFFA6A49B);       // Muted captions & placeholders
  static const Color body = Color(0xFF52504B);       // Body copy text

  // =========================================================================
  // 💡 DOSEN LIVE CHALLENGE: THEME & BRAND ACCENT COLOR
  // Jika dosen meminta mengubah warna aksen/tema (misal jadi Emerald atau Sapphire):
  // Ubah hex value `accent` di bawah:
  // - Gold bawaan: Color(0xFFC0A85C)
  // - Emerald Green: Color(0xFF059669)
  // - Sapphire Blue: Color(0xFF2563EB)
  // - Rose Titanium: Color(0xFFE11D48)
  // =========================================================================
  static const Color accent = Color(0xFFC0A85C);     // Signature Alpine Warm Gold
  static const Color accentWarm = Color(0xFFD97706); // Warm amber secondary
  static const Color badgeBg = Color(0xFFFEF3C7);    // Soft warm gold badge pill
  static const Color toastBg = Color(0xFF1D1D1B);    // Premium deep dark titanium for toasts/modals

  // Primary Action Button (Jet Black with Crisp White Text like Oyenza CTA)
  static const Color primaryButton = Color(0xFF141413);
  static const Color primaryButtonInk = Color(0xFFFFFFFF);

  // Profit / Loss Signals (Clean & Muted)
  static const Color pos = Color(0xFF16A34A);        // Positive gain green
  static const Color posBg = Color(0xFFDCFCE7);      // Soft green badge background
  static const Color neg = Color(0xFFDC2626);        // Negative loss red
  static const Color negBg = Color(0xFFFEE2E2);      // Soft red badge background
  static const Color warn = Color(0xFFD97706);       // Amber warning
  static const Color warnBg = Color(0xFFFEF3C7);     // Soft amber background

  // Delicate Morning Glow & Ambient Tokens
  static const Color sunsetTop = Color(0xFFFFF6EE);     // Soft warm peach glow
  static const Color sunsetMid = Color(0xFFFFF1E4);     // Delicate apricot wash
  static const Color sunsetBottom = Color(0xFFFAF9F6);  // Fades seamlessly into porcelain
  static const Color sunsetHaze = Color(0xFFFFFAF5);

  // Mascot Tokens
  static const Color vowlCharcoal = Color(0xFF2C2A28);
  static const Color vowlGold = Color(0xFFD97706);
  static const Color vowlCream = Color(0xFFF7F5EE);

  // Backwards-compatible aliases
  static const Color valtoOrange = vowlGold;
  static const Color valtoLight = vowlCream;
  static const Color valtoGold = vowlGold;

  // Soft Frosted Glass for Light Mode
  static Color glassBg = Colors.white.withValues(alpha: 0.85);
  static Color glassBorder = const Color(0xFF141413).withValues(alpha: 0.08);
}

/// Universal Toast & SnackBar Utility for consistent contrast across VAULTED
class VaultToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color iconColor = VaultColors.accent,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1D1D1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A2A28), width: 1),
        ),
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF2F2EF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

