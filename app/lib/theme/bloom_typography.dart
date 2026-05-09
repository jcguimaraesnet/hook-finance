// Spec: docs/specs/conventions.md
// Tipografia Bloom — Bricolage Grotesque (display), Inter (body), JetBrains Mono (números).
// Geist (Vercel) não está no Google Fonts — Inter/JetBrains Mono são substitutos
// equivalentes em peso/tom geométrico.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bloom_colors.dart';

class BloomTypography {
  BloomTypography._();

  static TextStyle geist({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? BloomColors.ink,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? BloomColors.ink,
        letterSpacing: letterSpacing ?? -0.6,
        height: height ?? 1.1,
      );

  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? BloomColors.ink,
        letterSpacing: letterSpacing,
      );

  /// Etiqueta uppercase pequena (ex: "TOTAL PESSOAL").
  static TextStyle kicker({Color? color}) => geist(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: color ?? BloomColors.muted,
        letterSpacing: 0.4,
      );

  static TextTheme textTheme() {
    return TextTheme(
      displayLarge: display(fontSize: 34, letterSpacing: -0.8),
      displayMedium: display(fontSize: 30, letterSpacing: -0.8),
      displaySmall: display(fontSize: 28, letterSpacing: -0.6),
      headlineLarge: display(fontSize: 24, letterSpacing: -0.5),
      headlineMedium: display(fontSize: 22, letterSpacing: -0.4),
      headlineSmall: display(fontSize: 20, letterSpacing: -0.4),
      titleLarge: display(fontSize: 18, letterSpacing: -0.4, height: 1.2),
      titleMedium: geist(fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall: geist(fontSize: 13, fontWeight: FontWeight.w600),
      bodyLarge: geist(fontSize: 15),
      bodyMedium: geist(fontSize: 13.5),
      bodySmall: geist(fontSize: 12, color: BloomColors.inkSoft),
      labelLarge: geist(fontSize: 13, fontWeight: FontWeight.w500),
      labelMedium: geist(fontSize: 11.5, fontWeight: FontWeight.w500),
      labelSmall: kicker(),
    );
  }
}
