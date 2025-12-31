import 'package:flutter/material.dart';

/// Parachute Design Tokens
///
/// Shared design language across Parachute apps.

// =============================================================================
// COLORS - Brand Palette
// =============================================================================

class BrandColors {
  BrandColors._();

  // Primary - Forest Green
  static const Color forest = Color(0xFF40695B);
  static const Color forestLight = Color(0xFF5A8577);
  static const Color forestMist = Color(0xFFD4E5DF);
  static const Color forestDeep = Color(0xFF2D4A40);

  // Secondary - Turquoise
  static const Color turquoise = Color(0xFF5EA8A7);
  static const Color turquoiseLight = Color(0xFF7FBFBE);
  static const Color turquoiseMist = Color(0xFFD5ECEB);
  static const Color turquoiseDeep = Color(0xFF3D8584);

  // Neutrals
  static const Color cream = Color(0xFFFAF9F7);
  static const Color softWhite = Color(0xFFFFFEFC);
  static const Color stone = Color(0xFFE8E6E3);
  static const Color driftwood = Color(0xFF9B9590);
  static const Color charcoal = Color(0xFF3D3A37);
  static const Color ink = Color(0xFF1F1D1B);

  // Semantic Colors
  static const Color success = Color(0xFF6B9B7A);
  static const Color successLight = Color(0xFFE3F0E7);
  static const Color warning = Color(0xFFD4A056);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFB86B5A);
  static const Color errorLight = Color(0xFFFBEAE6);
  static const Color info = Color(0xFF6B8BA8);
  static const Color infoLight = Color(0xFFE6EEF4);

  // Dark Mode
  static const Color nightSurface = Color(0xFF1A1917);
  static const Color nightSurfaceElevated = Color(0xFF262523);
  static const Color nightForest = Color(0xFF7AB09D);
  static const Color nightTurquoise = Color(0xFF8CCFCE);
  static const Color nightText = Color(0xFFE8E5E1);
  static const Color nightTextSecondary = Color(0xFFA09B95);
}

// =============================================================================
// SPACING
// =============================================================================

class Spacing {
  Spacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);
}

// =============================================================================
// RADII
// =============================================================================

class Radii {
  Radii._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;

  static BorderRadius card = BorderRadius.circular(lg);
  static BorderRadius button = BorderRadius.circular(md);
  static BorderRadius badge = BorderRadius.circular(sm);
  static BorderRadius pill = BorderRadius.circular(full);
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================

class TypographyTokens {
  TypographyTokens._();

  static const double displayLarge = 48.0;
  static const double displayMedium = 36.0;
  static const double displaySmall = 28.0;
  static const double headlineLarge = 24.0;
  static const double headlineMedium = 20.0;
  static const double headlineSmall = 18.0;
  static const double titleLarge = 18.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 13.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.7;
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
}

// =============================================================================
// ELEVATION
// =============================================================================

class Elevation {
  Elevation._();

  static const double none = 0.0;
  static const double low = 1.0;
  static const double medium = 4.0;
  static const double high = 8.0;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: BrandColors.charcoal.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: BrandColors.charcoal.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}

// =============================================================================
// ANIMATION
// =============================================================================

class Motion {
  Motion._();

  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration gentle = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve settling = Curves.easeOutCubic;
  static const Curve breathe = Curves.easeInOut;
  static const Curve lift = Curves.easeOutQuart;
}
