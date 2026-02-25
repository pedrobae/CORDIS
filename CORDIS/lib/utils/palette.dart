import 'package:flutter/material.dart';

class Palette {
  // Five color palette
  // PALETTE
  static const Color _green = Color(0xFF145550); // Green
  static const Color _orange = Color(0xFFE66423); // Orange
  static const Color _gold = Color(0xFFE6B428); // Gold
  static const Color _burgundy = Color(0xFF5A002D); // Burgundy
  static const Color _neutral = Colors.white; // Neutral
  static const Color _darkNeutral = Color(0xFF121214); // Dark Neutral

  /// Lighten a color by [amount] (0.0 to 1.0)
  static Color lighten(Color color, [double amount = .08]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// Darken a color by [amount] (0.0 to 1.0)
  static Color darken(Color color, [double amount = .08]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class BrandPalette extends Palette {
  static final Color white = Palette._neutral;
  static final Color black = Palette._darkNeutral;

  // ===== PRECOMPUTED COLORS ======
  // GREEN THEME
  // PRIMARIES (Green)
  static final Color green = Palette._green;
  static final Color greenTint = const Color.fromARGB(255, 200, 226, 223);

  // =============================================================================
  // ORANGE THEME
  // PRIMARIES (Orange)
  static final Color orange = Palette._orange;
  static final Color orangeTint = Color.fromARGB(255, 65, 52, 48);

  // =============================================================================
  // GOLD THEME
  // PRIMARIES (Gold)
  static final Color gold = Palette._gold;
  static final Color goldTint = const Color.fromARGB(255, 39, 35, 24);

  // =============================================================================
  //  BURGUNDY THEME
  //  PRIMARIES (burgundy)
  static final Color burgundy = Palette._burgundy;
  static final Color burgundyTint = const Color.fromARGB(255, 233, 211, 222);
}

class NeutralPalette extends Palette {
  // Neutral colors for surfaces using final with calculations
  static final Color surface1Light = Palette.darken(Palette._neutral, 0.25);
  static final Color surface2Light = Palette.darken(Palette._neutral, 0.2);
  static final Color surface3Light = Palette.darken(Palette._neutral, 0.15);
  static final Color surface4Light = Palette.darken(Palette._neutral, 0.1);
  static final Color surface5Light = Palette.darken(Palette._neutral, 0.05);
  static final Color surfaceLight = Palette._neutral;

  static final Color surface1Dark = Palette.lighten(Palette._darkNeutral, 0.25);
  static final Color surface2Dark = Palette.lighten(Palette._darkNeutral, 0.2);
  static final Color surface3Dark = Palette.lighten(Palette._darkNeutral, 0.15);
  static final Color surface4Dark = Palette.lighten(Palette._darkNeutral, 0.1);
  static final Color surface5Dark = Palette.lighten(Palette._darkNeutral, 0.05);
  static final Color surfaceDark = Palette._darkNeutral;

  // Neutral elements using final with calculations
  static final Color outlineLight = Palette.darken(
    Palette._neutral,
    0.5,
  ); // Light outline
  static final Color outlineDark = Palette.lighten(
    Palette._darkNeutral,
    0.5,
  ); // Dark outline

  static const Color shadowLight = Color.fromARGB(127, 0, 0, 0); // Light shadow
  static const Color shadowDark = Color.fromARGB(
    127,
    168,
    168,
    168,
  ); // Dark shadow
  static const Color scrimLight = Color(0x0D000000); // Light scrim (5% opacity)
  static const Color scrimDark = Color(0x1A000000); // Dark scrim (10% opacity)

  static const Color error = Colors.red; // Standard error red
  static const Color onError = Color(0xFFFFFFFF); // White text for contrast
}
