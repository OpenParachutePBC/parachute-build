import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Parachute Build Theme
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: BrandColors.forest,
      onPrimary: BrandColors.softWhite,
      primaryContainer: BrandColors.forestMist,
      onPrimaryContainer: BrandColors.forestDeep,
      secondary: BrandColors.turquoise,
      onSecondary: BrandColors.softWhite,
      secondaryContainer: BrandColors.turquoiseMist,
      onSecondaryContainer: BrandColors.turquoiseDeep,
      tertiary: BrandColors.warning,
      onTertiary: BrandColors.softWhite,
      error: BrandColors.error,
      onError: BrandColors.softWhite,
      errorContainer: BrandColors.errorLight,
      onErrorContainer: BrandColors.error,
      surface: BrandColors.cream,
      onSurface: BrandColors.charcoal,
      surfaceContainerHighest: BrandColors.stone,
      outline: BrandColors.driftwood,
      outlineVariant: BrandColors.stone,
    ),
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      backgroundColor: BrandColors.cream,
      foregroundColor: BrandColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: TypographyTokens.titleLarge,
        fontWeight: FontWeight.w600,
        color: BrandColors.charcoal,
        letterSpacing: TypographyTokens.letterSpacingTight,
      ),
    ),
    textTheme: _buildTextTheme(BrandColors.charcoal),
    cardTheme: CardThemeData(
      elevation: Elevation.low,
      color: BrandColors.softWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.forest,
        foregroundColor: BrandColors.softWhite,
        elevation: Elevation.low,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.softWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrandColors.stone),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrandColors.stone),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrandColors.forest, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: BrandColors.nightForest,
      onPrimary: BrandColors.nightSurface,
      primaryContainer: BrandColors.forestDeep,
      onPrimaryContainer: BrandColors.nightForest,
      secondary: BrandColors.nightTurquoise,
      onSecondary: BrandColors.nightSurface,
      secondaryContainer: BrandColors.turquoiseDeep,
      onSecondaryContainer: BrandColors.nightTurquoise,
      tertiary: BrandColors.warning,
      onTertiary: BrandColors.nightSurface,
      error: const Color(0xFFE8A090),
      onError: BrandColors.nightSurface,
      surface: BrandColors.nightSurface,
      onSurface: BrandColors.nightText,
      surfaceContainerHighest: BrandColors.nightSurfaceElevated,
      outline: BrandColors.nightTextSecondary,
    ),
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      backgroundColor: BrandColors.nightSurface,
      foregroundColor: BrandColors.nightText,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: TypographyTokens.titleLarge,
        fontWeight: FontWeight.w600,
        color: BrandColors.nightText,
        letterSpacing: TypographyTokens.letterSpacingTight,
      ),
    ),
    textTheme: _buildTextTheme(BrandColors.nightText),
    cardTheme: CardThemeData(
      elevation: Elevation.low,
      color: BrandColors.nightSurfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.nightForest,
        foregroundColor: BrandColors.nightSurface,
        elevation: Elevation.low,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.nightSurfaceElevated,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: Color(0xFF3A3836)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: Color(0xFF3A3836)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrandColors.nightForest, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
  );

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      headlineLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.headlineLarge,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.headlineMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.titleLarge,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.titleMedium,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.bodyLarge,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: TypographyTokens.lineHeightRelaxed,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.bodyMedium,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: TypographyTokens.lineHeightRelaxed,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.labelLarge,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.labelMedium,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}
