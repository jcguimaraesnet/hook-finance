// Spec: docs/specs/conventions.md
// Tema Bloom — paleta lavanda+menta com Bricolage Grotesque/Geist.

import 'package:flutter/material.dart';
import 'bloom_colors.dart';
import 'bloom_typography.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BloomColors.violet,
    brightness: Brightness.light,
  ).copyWith(
    primary: BloomColors.violet,
    secondary: BloomColors.mint,
    tertiary: BloomColors.sky,
    error: BloomColors.bad,
    surface: BloomColors.bg3,
    onSurface: BloomColors.ink,
    onSurfaceVariant: BloomColors.inkSoft,
    outlineVariant: BloomColors.border,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: BloomTypography.textTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: BloomColors.ink),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: BloomColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: BloomColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BloomColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BloomColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BloomColors.violet, width: 1.5),
      ),
      filled: true,
      fillColor: BloomColors.bg3,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    iconTheme: const IconThemeData(color: BloomColors.ink, size: 20),
    dividerTheme: const DividerThemeData(
      color: BloomColors.divider,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
