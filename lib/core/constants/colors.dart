import 'package:flutter/material.dart';

/// Exact ultra-luxury Dark Titanium design system for VAULTED
/// Defined by the Vantis Vault dark titanium aesthetic.
class VaultColors {
  // Canvas & Surfaces (Dark Titanium)
  static const Color background = Color(0xFF131312); // Deep titanium black canvas
  static const Color card = Color(0xFF1D1D1B);       // Rich dark card surface
  static const Color cardHover = Color(0xFF252523);  // Elevated card / hover surface
  static const Color hairline = Color(0xFF2A2A28);   // Delicate hairline divider

  // Typography & Inks
  static const Color ink = Color(0xFFF2F2EF);        // Crisp off-white primary text
  static const Color ink2 = Color(0xFF8F8F8A);       // Refined secondary titanium text
  static const Color ink3 = Color(0xFF5C5C58);       // Muted captions & borders
  static const Color body = Color(0xFFA8A8A2);       // Body copy text

  // Signature Luxury Accents & Badges
  static const Color accent = Color(0xFFC0A85C);     // Signature warm luxury gold
  static const Color badgeBg = Color(0xFF2C2717);    // Dark warm gold badge background

  // Action Buttons
  static const Color primaryButton = Color(0xFFC0A85C);
  static const Color primaryButtonInk = Color(0xFF131312);

  // Profit / Loss Signals (Subtle Muted Tones)
  static const Color pos = Color(0xFF6FAE88);        // Muted sage green gain
  static const Color posBg = Color(0xFF1A261E);      // Dark sage badge background
  static const Color neg = Color(0xFFC98A76);        // Muted terracotta loss
  static const Color negBg = Color(0xFF2A1C18);      // Dark terracotta badge background

  // Ambient Glow Tokens
  static const Color sunsetTop = Color(0xFF382E47);
  static const Color sunsetMid = Color(0xFF4A342C);
  static const Color sunsetBottom = Color(0xFF1D1D1B);
  static const Color sunsetHaze = Color(0xFF242422);

  // Valto & Mascot Tokens
  static const Color vowlCharcoal = Color(0xFF141413);
  static const Color vowlGold = Color(0xFFC0A85C);
  static const Color vowlCream = Color(0xFFF2F2EF);

  // Backwards-compatible aliases
  static const Color valtoOrange = vowlGold;
  static const Color valtoLight = vowlCream;
  static const Color valtoGold = vowlGold;

  // Frosted Glass for Dark Titanium
  static Color glassBg = const Color(0xFF1D1D1B).withValues(alpha: 0.70);
  static Color glassBorder = const Color(0xFFF2F2EF).withValues(alpha: 0.12);
}
