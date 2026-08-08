import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  THE ARCHIVIST'S GRIMOIRE — Color Palette
//  Source: stitch_mystic_ledger_ui_design HTML files
// ─────────────────────────────────────────────
//
// The palette is deliberately *mutable* static state rather than const: every
// screen reads `MysticColors.background` (etc.) directly, so a true dark mode
// has to swap the values at runtime. [MysticColors.useDark] reassigns all of
// them in one step and every existing screen follows along on the next build.
class MysticColors {
  // Backgrounds & surfaces (parchment layers)
  static Color background              = const Color(0xFFFBFBE2);
  static Color surface                 = const Color(0xFFFBFBE2);
  static Color surfaceContainerLowest  = const Color(0xFFFFFFFF);
  static Color surfaceContainerLow     = const Color(0xFFF5F5DC);
  static Color surfaceContainer        = const Color(0xFFEFEFD7);
  static Color surfaceContainerHigh    = const Color(0xFFEAEAD1);
  static Color surfaceContainerHighest = const Color(0xFFE4E4CC);
  static Color surfaceDim              = const Color(0xFFDBDCC3);

  // Primary — Dark Gold (#735c00) + Container Bright Gold (#d4af37)
  static Color primary                 = const Color(0xFF735C00);
  static Color primaryContainer        = const Color(0xFFD4AF37);
  static Color primaryFixed            = const Color(0xFFFFE088);
  static Color onPrimary               = const Color(0xFFFFFFFF);
  static Color onPrimaryContainer      = const Color(0xFF554300);

  // Secondary — Forest Green (income)
  static Color secondary               = const Color(0xFF3C6929);
  static Color secondaryContainer      = const Color(0xFFBCF1A1);
  static Color onSecondary             = const Color(0xFFFFFFFF);
  static Color onSecondaryContainer    = const Color(0xFF426F2F);

  // Tertiary — Oxblood Red (expense)
  static Color tertiary                = const Color(0xFFAD302F);
  static Color tertiaryContainer       = const Color(0xFFFF968F);
  static Color onTertiary              = const Color(0xFFFFFFFF);

  // Text & outlines
  static Color onSurface               = const Color(0xFF1B1D0E);
  static Color onSurfaceVariant        = const Color(0xFF4D4635);
  static Color outline                 = const Color(0xFF7F7663);
  static Color outlineVariant          = const Color(0xFFD0C5AF);

  // Error
  static Color error                   = const Color(0xFFBA1A1A);
  static Color onError                 = const Color(0xFFFFFFFF);

  /// AppBar tint used by screens that hard-code a parchment bar. Follows the
  /// mode so dark screens never keep a white bar.
  static Color appBarBackground = const Color(0xFFFDFCF0);

  /// Restores the parchment light palette.
  static void useLight() {
    background              = const Color(0xFFFBFBE2);
    surface                 = const Color(0xFFFBFBE2);
    surfaceContainerLowest  = const Color(0xFFFFFFFF);
    surfaceContainerLow     = const Color(0xFFF5F5DC);
    surfaceContainer        = const Color(0xFFEFEFD7);
    surfaceContainerHigh    = const Color(0xFFEAEAD1);
    surfaceContainerHighest = const Color(0xFFE4E4CC);
    surfaceDim              = const Color(0xFFDBDCC3);
    primary                 = const Color(0xFF735C00);
    primaryContainer        = const Color(0xFFD4AF37);
    primaryFixed            = const Color(0xFFFFE088);
    onPrimary               = const Color(0xFFFFFFFF);
    onPrimaryContainer      = const Color(0xFF554300);
    secondary               = const Color(0xFF3C6929);
    secondaryContainer      = const Color(0xFFBCF1A1);
    onSecondary             = const Color(0xFFFFFFFF);
    onSecondaryContainer    = const Color(0xFF426F2F);
    tertiary                = const Color(0xFFAD302F);
    tertiaryContainer       = const Color(0xFFFF968F);
    onTertiary              = const Color(0xFFFFFFFF);
    onSurface               = const Color(0xFF1B1D0E);
    onSurfaceVariant        = const Color(0xFF4D4635);
    outline                 = const Color(0xFF7F7663);
    outlineVariant          = const Color(0xFFD0C5AF);
    error                   = const Color(0xFFBA1A1A);
    onError                 = const Color(0xFFFFFFFF);
    appBarBackground        = const Color(0xFFFDFCF0);
  }

  /// Switches to the deep-charcoal night palette.
  static void useDark() {
    background              = const Color(0xFF191812); // charcoal parchment
    surface                 = const Color(0xFF191812);
    surfaceContainerLowest  = const Color(0xFF232119);
    surfaceContainerLow     = const Color(0xFF232119);
    surfaceContainer        = const Color(0xFF2A2820);
    surfaceContainerHigh    = const Color(0xFF32302A);
    surfaceContainerHighest = const Color(0xFF3A3832);
    surfaceDim              = const Color(0xFF141310);
    primary                 = const Color(0xFFE3BE5C); // bright gold
    primaryContainer        = const Color(0xFFC9A227);
    primaryFixed            = const Color(0xFFEED083);
    onPrimary               = const Color(0xFF3A2F00);
    onPrimaryContainer      = const Color(0xFFFFF3C9);
    secondary               = const Color(0xFF8FD477); // bright forest
    secondaryContainer      = const Color(0xFF3A5C2E);
    onSecondary             = const Color(0xFF0E1F06);
    onSecondaryContainer    = const Color(0xFFD2F0C0);
    tertiary                = const Color(0xFFE08A82); // soft oxblood
    tertiaryContainer       = const Color(0xFF6E2B29);
    onTertiary              = const Color(0xFF2A0606);
    onSurface               = const Color(0xFFEDE9D8);
    onSurfaceVariant        = const Color(0xFFB8B09B);
    outline                 = const Color(0xFF8F8771);
    outlineVariant          = const Color(0xFF4C4737);
    error                   = const Color(0xFFFFB4AB);
    onError                 = const Color(0xFF690005);
    appBarBackground        = const Color(0xFF232119);
  }
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
      onTertiaryContainer: Color(0xFF8A1519),
      error: MysticColors.error,
      onError: MysticColors.onError,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
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
      inverseSurface: Color(0xFF303221),
      onInverseSurface: Color(0xFFF2F2D9),
      inversePrimary: Color(0xFFE9C349),
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
      backgroundColor: MysticColors.appBarBackground,
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
//  Dark theme
//  The palette is already swapped by MysticColors.useDark(); this ThemeData
//  only reflects the same brightness for Material widgets (dialogs, pickers,
//  date pickers) that consult Theme.of().
// ─────────────────────────────────────────────
ThemeData buildMysticDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
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
      onTertiaryContainer: Color(0xFFFFB4AC),
      error: MysticColors.error,
      onError: MysticColors.onError,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
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
      inverseSurface: Color(0xFFEDE9D8),
      onInverseSurface: Color(0xFF303221),
      inversePrimary: Color(0xFF735C00),
      surfaceTint: MysticColors.primary,
    ),
    scaffoldBackgroundColor: MysticColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: MysticColors.appBarBackground,
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
