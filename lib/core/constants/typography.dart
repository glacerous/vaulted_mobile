import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class VaultTypography {
  // Monospace - for money, percentages, dates, and metric data
  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = VaultColors.ink,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Sans (Inter) - for UI labels, titles, and body content
  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = VaultColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Pre-configured text styles matching Vantis Vault
  static TextStyle get heroTotal => mono(
    fontSize: 34,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02,
  );

  static TextStyle get sectionTitle => sans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01,
  );

  static TextStyle get cardLabel => sans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: VaultColors.ink,
  );

  static TextStyle get cardSub => sans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: VaultColors.ink2,
  );

  static TextStyle get cardDescription => sans(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: VaultColors.body,
    height: 1.4,
  );

  static TextStyle get badgeLabel => mono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: VaultColors.pos,
  );
}
