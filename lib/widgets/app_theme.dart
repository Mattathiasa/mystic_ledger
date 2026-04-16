import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  THE ARCHIVIST'S GRIMOIRE — Color Palette
//  Source: stitch_mystic_ledger_ui_design HTML files
// ─────────────────────────────────────────────
class MysticColors {
  // Backgrounds & surfaces (parchment layers)
  static const background              = Color(0xFFFBFBE2);
  static const surface                 = Color(0xFFFBFBE2);
  static const surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const surfaceContainerLow     = Color(0xFFF5F5DC);
  static const surfaceContainer        = Color(0xFFEFEFD7);
  static const surfaceContainerHigh    = Color(0xFFEAEAD1);
  static const surfaceContainerHighest = Color(0xFFE4E4CC);
  static const surfaceDim              = Color(0xFFDBDCC3);

  // Primary — Dark Gold (#735c00) + Container Bright Gold (#d4af37)
  static const primary                 = Color(0xFF735C00);
  static const primaryContainer        = Color(0xFFD4AF37);
  static const primaryFixed            = Color(0xFFFFE088);
  static const onPrimary               = Color(0xFFFFFFFF);
  static const onPrimaryContainer      = Color(0xFF554300);

  // Secondary — Forest Green (income)
  static const secondary               = Color(0xFF3C6929);
  static const secondaryContainer      = Color(0xFFBCF1A1);
  static const onSecondary             = Color(0xFFFFFFFF);
  static const onSecondaryContainer    = Color(0xFF426F2F);

  // Tertiary — Oxblood Red (expense)
  static const tertiary                = Color(0xFFAD302F);
  static const tertiaryContainer       = Color(0xFFFF968F);
  static const onTertiary              = Color(0xFFFFFFFF);

  // Text & outlines
  static const onSurface               = Color(0xFF1B1D0E);
  static const onSurfaceVariant        = Color(0xFF4D4635);
  static const outline                 = Color(0xFF7F7663);
  static const outlineVariant          = Color(0xFFD0C5AF);

  // Error
  static const error                   = Color(0xFFBA1A1A);
  static const onError                 = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────
//  Full Material 3 ThemeData
// ─────────────────────────────────────────────
ThemeData buildMysticTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: MysticColors.primary,
      onPrimary: MysticColors.onPrimary,
      primaryContainer: MysticColors.primaryContainer,
      onPrimaryContainer: MysticColors.onPrimaryContainer,
      secondary: MysticColors.secondary,
      onSecondary: MysticColors.onSecondary,
      secondaryContainer: MysticColors.secondaryContainer,
      onSecondaryContainer: MysticColors.onSecondaryContainer,
      tertiary: MysticColors.tertiary,
      onTertiary: MysticColors.onTertiary,
      tertiaryContainer: MysticColors.tertiaryContainer,
      onTertiaryContainer: const Color(0xFF8A1519),
      error: MysticColors.error,
      onError: MysticColors.onError,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
      surface: MysticColors.surface,
      onSurface: MysticColors.onSurface,
      onSurfaceVariant: MysticColors.onSurfaceVariant,
      outline: MysticColors.outline,
      outlineVariant: MysticColors.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      // ignore: deprecated_member_use
      background: MysticColors.background,
      // ignore: deprecated_member_use
      onBackground: MysticColors.onSurface,
      inverseSurface: const Color(0xFF303221),
      onInverseSurface: const Color(0xFFF2F2D9),
      inversePrimary: const Color(0xFFE9C349),
      surfaceTint: MysticColors.primary,
    ),
    scaffoldBackgroundColor: MysticColors.background,
    // App-wide text theme: Epilogue headlines, Manrope body, Space Grotesk labels
    textTheme: TextTheme(
      displayLarge:  GoogleFonts.epilogue(fontSize: 57, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: MysticColors.onSurface),
      displayMedium: GoogleFonts.epilogue(fontSize: 45, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: MysticColors.onSurface),
      displaySmall:  GoogleFonts.epilogue(fontSize: 36, fontWeight: FontWeight.w900, color: MysticColors.onSurface),
      headlineLarge: GoogleFonts.epilogue(fontSize: 32, fontWeight: FontWeight.w800, color: MysticColors.onSurface),
      headlineMedium:GoogleFonts.epilogue(fontSize: 28, fontWeight: FontWeight.w700, color: MysticColors.onSurface),
      headlineSmall: GoogleFonts.epilogue(fontSize: 24, fontWeight: FontWeight.w700, color: MysticColors.onSurface),
      titleLarge:    GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.w700, color: MysticColors.onSurface),
      titleMedium:   GoogleFonts.manrope(fontSize: 16,  fontWeight: FontWeight.w600, color: MysticColors.onSurface),
      titleSmall:    GoogleFonts.manrope(fontSize: 14,  fontWeight: FontWeight.w600, color: MysticColors.onSurface),
      bodyLarge:     GoogleFonts.manrope(fontSize: 16,  color: MysticColors.onSurface),
      bodyMedium:    GoogleFonts.manrope(fontSize: 14,  color: MysticColors.onSurface),
      bodySmall:     GoogleFonts.manrope(fontSize: 12,  color: MysticColors.onSurfaceVariant),
      labelLarge:    GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: MysticColors.onSurface),
      labelMedium:   GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: MysticColors.onSurfaceVariant),
      labelSmall:    GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: MysticColors.onSurfaceVariant),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFFDFCF0),
      foregroundColor: MysticColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.epilogue(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: MysticColors.onSurface,
        letterSpacing: -0.5,
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  Convenience style helpers
//  Used throughout screens so font decisions stay in one place.
// ─────────────────────────────────────────────

/// Epilogue — for all titles, headings, hero numbers
TextStyle headlineStyle(
  double size, {
  FontWeight weight = FontWeight.w900,
  bool italic = true,
  Color? color,
}) =>
    GoogleFonts.epilogue(
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color ?? MysticColors.onSurface,
    );

/// Manrope — for body copy, amounts, descriptions
TextStyle bodyStyle(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color ?? MysticColors.onSurface,
    );

/// Space Grotesk — for labels, badges, metadata (uppercase)
TextStyle labelStyle(
  double size, {
  FontWeight weight = FontWeight.w500,
  double letterSpacing = 0,
  Color? color,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? MysticColors.onSurfaceVariant,
    );
