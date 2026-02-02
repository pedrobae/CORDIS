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
  // ===== PRECOMPUTED COLORS ======

  // GREEN THEME
  // PRIMARIES (Green)
  static final Color greenLight = Palette._green;
  static final Color greenDark = Palette._green;
  static final Color greenOnLight = Palette._neutral;
  static final Color greenOnDark = Palette._neutral;
  static final Color greenContainerLight = Palette.lighten(
    Palette._green,
    0.18,
  );
  static final Color greenContainerDark = Palette.darken(Palette._green, 0.12);
  static final Color greenOnContainerLight = Palette._darkNeutral;
  static final Color greenOnContainerDark = Palette._neutral;

  // ACCENT 1 (Green + Orange)
  static final Color greenAccent1 = Color.alphaBlend(
    Palette._orange.withAlpha(0x40), // 25% blend
    Palette._green,
  );
  static final Color greenAccent1Light = greenAccent1;
  static final Color greenAccent1Dark = Palette.darken(greenAccent1, 0.1);
  static final Color greenOnAccent1Light = Palette._darkNeutral;
  static final Color greenOnAccent1Dark = Palette._neutral;
  static final Color greenAccent1ContainerLight = Palette.lighten(
    greenAccent1,
    0.2,
  );
  static final Color greenAccent1ContainerDark = Palette.darken(
    greenAccent1,
    0.17,
  );
  static final Color greenOnAccent1ContainerLight = Palette._darkNeutral;
  static final Color greenOnAccent1ContainerDark = Palette._neutral;

  // ACCENT 2 (Green + Gold)
  static final Color greenAccent2 = Color.alphaBlend(
    Palette._gold.withAlpha(0x38), // 22% blend
    Palette._green,
  );
  static final Color greenAccent2Light = Palette.lighten(greenAccent2, 0.15);
  static final Color greenAccent2Dark = Palette.darken(greenAccent2, 0.09);
  static final Color greenOnAccent2Light = Palette._darkNeutral;
  static final Color greenOnAccent2Dark = Palette._neutral;
  static final Color greenAccent2ContainerLight = Palette.lighten(
    greenAccent2,
    0.25,
  );
  static final Color greenAccent2ContainerDark = Palette.darken(
    greenAccent2,
    0.22,
  );
  static final Color greenOnAccent2ContainerLight = Palette._darkNeutral;
  static final Color greenOnAccent2ContainerDark = Palette._neutral;

  // =============================================================================
  // ORANGE THEME
  // PRIMARIES (Orange)
  static final Color orangeLight = Palette._orange;
  static final Color orangeDark = Palette.darken(Palette._orange, 0.15);
  static final Color orangeOnLight = Palette._darkNeutral;
  static final Color orangeOnDark = Palette._neutral;
  static final Color orangeContainerLight = Palette.lighten(
    Palette._orange,
    0.18,
  );
  static final Color orangeContainerDark = Palette.darken(
    Palette._orange,
    0.25,
  );
  static final Color orangeOnContainerLight = Palette._darkNeutral;
  static final Color orangeOnContainerDark = Palette._neutral;

  // ACCENT 1 (Orange + Green)
  static final Color orangeAccent1 = Color.alphaBlend(
    Palette._green.withAlpha(0x40), // 25% blend
    Palette._orange,
  );
  static final Color orangeAccent1Light = orangeAccent1;
  static final Color orangeAccent1Dark = Palette.darken(orangeAccent1, 0.1);
  static final Color orangeOnAccent1Light = Palette._darkNeutral;
  static final Color orangeOnAccent1Dark = Palette._neutral;
  static final Color orangeAccent1ContainerLight = Palette.lighten(
    orangeAccent1,
    0.2,
  );
  static final Color orangeAccent1ContainerDark = Palette.darken(
    orangeAccent1,
    0.17,
  );
  static final Color orangeOnAccent1ContainerLight = Palette._darkNeutral;
  static final Color orangeOnAccent1ContainerDark = Palette._neutral;

  // ACCENT 2 (Orange + Gold)
  static final Color orangeAccent2 = Color.alphaBlend(
    Palette._gold.withAlpha(0x38), // 22% blend
    Palette._orange,
  );
  static final Color orangeAccent2Light = Palette.lighten(orangeAccent2, 0.15);
  static final Color orangeAccent2Dark = Palette.darken(orangeAccent2, 0.09);
  static final Color orangeOnAccent2Light = Palette._darkNeutral;
  static final Color orangeOnAccent2Dark = Palette._neutral;
  static final Color orangeAccent2ContainerLight = Palette.lighten(
    orangeAccent2,
    0.25,
  );
  static final Color orangeAccent2ContainerDark = Palette.darken(
    orangeAccent2,
    0.22,
  );
  static final Color orangeOnAccent2ContainerLight = Palette._darkNeutral;
  static final Color orangeOnAccent2ContainerDark = Palette._neutral;

  // =============================================================================
  // GOLD THEME
  // PRIMARIES (Gold)
  static final Color goldLight = Palette._gold;
  static final Color goldDark = Palette._gold;
  static final Color goldOnLight = Palette._darkNeutral;
  static final Color goldOnDark = Palette._darkNeutral;
  static final Color goldContainerLight = Palette.lighten(Palette._gold, 0.12);
  static final Color goldContainerDark = Palette.darken(Palette._gold, 0.17);
  static final Color goldOnContainerLight = Palette._darkNeutral;
  static final Color goldOnContainerDark = Palette._darkNeutral;

  // ACCENT 1 (Gold + Orange)
  static final Color goldAccent1 = Color.alphaBlend(
    Palette._gold.withAlpha(0x70),
    Palette._orange,
  );
  static final Color goldAccent1Light = goldAccent1;
  static final Color goldAccent1Dark = Palette.darken(goldAccent1, 0.06);
  static final Color goldOnAccent1Light = Palette._darkNeutral;
  static final Color goldOnAccent1Dark = Palette._darkNeutral;
  static final Color goldAccent1ContainerLight = Palette.lighten(
    goldAccent1,
    0.12,
  );
  static final Color goldAccent1ContainerDark = Palette.darken(
    goldAccent1,
    0.16,
  );
  static final Color goldOnAccent1ContainerLight = Palette._darkNeutral;
  static final Color goldOnAccent1ContainerDark = Palette._neutral;

  // ACCENT 2 (Gold + Burgundy)
  static final Color goldAccent2 = Color.alphaBlend(
    Palette._gold.withAlpha(0x50),
    Palette._burgundy,
  );
  static final Color goldAccent2Light = Palette.lighten(goldAccent2, 0.08);
  static final Color goldAccent2Dark = Palette.darken(goldAccent2, 0.01);
  static final Color goldOnAccent2Light = Palette._darkNeutral;
  static final Color goldOnAccent2Dark = Palette._neutral;
  static final Color goldAccent2ContainerLight = Palette.lighten(
    goldAccent2,
    0.15,
  );
  static final Color goldAccent2ContainerDark = Palette.darken(
    goldAccent2,
    0.14,
  );
  static final Color goldOnAccent2ContainerLight = Palette._darkNeutral;
  static final Color goldOnAccent2ContainerDark = Palette._neutral;

  // =============================================================================
  // BURGUNDY THEME
  // PRIMARIES (Burgundy)
  static final Color burgundyLight = Palette._burgundy;
  static final Color burgundyDark = Palette.darken(Palette._burgundy, 0.03);
  static final Color burgundyOnLight = Palette._neutral;
  static final Color burgundyOnDark = Palette._neutral;
  static final Color burgundyContainerLight = Palette.lighten(
    Palette._burgundy,
    0.07,
  );
  static final Color burgundyContainerDark = Palette.darken(
    Palette._burgundy,
    0.11,
  );
  static final Color burgundyOnContainerLight = Palette._neutral;
  static final Color burgundyOnContainerDark = Palette._neutral;

  // ACCENT 1 (Burgundy + Gold)
  static final Color burgundyAccent1 = Color.alphaBlend(
    Palette._gold.withAlpha(0x40), // 25% blend
    Palette._burgundy,
  );
  static final Color burgundyAccent1Light = burgundyAccent1;
  static final Color burgundyAccent1Dark = Palette.darken(burgundyAccent1, 0.1);
  static final Color burgundyOnAccent1Light = Palette._neutral;
  static final Color burgundyOnAccent1Dark = Palette._neutral;
  static final Color burgundyAccent1ContainerLight = Palette.lighten(
    burgundyAccent1,
    0.1,
  );
  static final Color burgundyAccent1ContainerDark = Palette.darken(
    burgundyAccent1,
    0.19,
  );
  static final Color burgundyOnAccent1ContainerLight = Palette._neutral;
  static final Color burgundyOnAccent1ContainerDark = Palette._neutral;

  // ACCENT 2 (Burgundy + Green)
  static final Color burgundyAccent2 = Color.alphaBlend(
    Palette._green.withAlpha(0x38), // 22% blend
    Palette._burgundy,
  );
  static final Color burgundyAccent2Light = Palette.lighten(
    burgundyAccent2,
    0.15,
  );
  static final Color burgundyAccent2Dark = Palette.darken(
    burgundyAccent2,
    0.01,
  );
  static final Color burgundyOnAccent2Light = Palette._neutral;
  static final Color burgundyOnAccent2Dark = Palette._neutral;
  static final Color burgundyAccent2ContainerLight = Palette.lighten(
    burgundyAccent2,
    0.22,
  );
  static final Color burgundyAccent2ContainerDark = Palette.darken(
    burgundyAccent2,
    0.06,
  );
  static final Color burgundyOnAccent2ContainerLight = Palette._neutral;
  static final Color burgundyOnAccent2ContainerDark = Palette._neutral;
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
