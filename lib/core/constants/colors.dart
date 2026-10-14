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

  // Accents & Badges
  static const Color accent = Color(0xFFD97706);     // Warm golden amber signature
  static const Color badgeBg = Color(0xFFFEF3C7);    // Soft warm gold badge pill

  // Primary Action Button (Jet Black with Crisp White Text like Oyenza CTA)
  static const Color primaryButton = Color(0xFF141413);
  static const Color primaryButtonInk = Color(0xFFFFFFFF);

  // Profit / Loss Signals
  static const Color pos = Color(0xFF16A34A);        // Positive gain green
  static const Color posBg = Color(0xFFDCFCE7);      // Soft green badge background
  static const Color neg = Color(0xFFDC2626);        // Negative loss red
  static const Color negBg = Color(0xFFFEE2E2);      // Soft red badge background

  // Delicate Morning Glow & Ambient Tokens
  static const Color sunsetTop = Color(0xFFFFF6EE);     // Soft warm peach glow
  static const Color sunsetMid = Color(0xFFFFF1E4);     // Delicate apricot wash
  static const Color sunsetBottom = Color(0xFFFAF9F6);  // Fades seamlessly into porcelain
  static const Color sunsetHaze = Color(0xFFFFFAF5);

  // Vowl & Vault Mascot Tokens
  static const Color vowlCharcoal = Color(0xFF2C2A28); // Owl sleek feathers
  static const Color vowlGold = Color(0xFFD97706);     // Owl vault lock iris
  static const Color vowlCream = Color(0xFFF7F5EE);    // Owl chest / mask

  // Backwards-compatible aliases
  static const Color valtoOrange = vowlGold;
  static const Color valtoLight = vowlCream;
  static const Color valtoGold = vowlGold;

  // Soft Frosted Glass for Light Mode
  static Color glassBg = Colors.white.withValues(alpha: 0.85);
  static Color glassBorder = const Color(0xFF141413).withValues(alpha: 0.08);
}
