import 'package:flutter/material.dart';

/// Exact color palette extracted from Vantis Vault (https://vault.vantis.sh/)
class VaultColors {
  // Canvas & Surfaces
  static const Color background = Color(0xFF131312);
  static const Color card = Color(0xFF1D1D1B);
  static const Color cardHover = Color(0xFF242422);
  static const Color hairline = Color(0xFF2A2A28);

  // Typography & Inks
  static const Color ink = Color(0xFFF2F2EF);      // Primary text
  static const Color ink2 = Color(0xFF8F8F8A);     // Secondary muted text
  static const Color ink3 = Color(0xFF5C5C58);     // Muted borders / faint labels
  static const Color body = Color(0xFF9C9C96);     // Body paragraph text

  // Accents & Badges
  static const Color accent = Color(0xFFC0A85C);   // Signature warm gold
  static const Color badgeBg = Color(0xFF2C2717);  // Dark warm gold badge background

  // Profit / Loss Signals
  static const Color pos = Color(0xFF6FAE88);      // Positive gain green
  static const Color posBg = Color(0xFF1D2A22);    // Positive badge green
  static const Color neg = Color(0xFFC98A76);      // Negative loss red
  static const Color negBg = Color(0xFF2E211C);    // Negative badge red
}
