import 'package:flutter/material.dart';
import 'package:cordeos/utils/string_utils.dart';

class ColorHelpers {
  /// Generates theme-appropriate colors for tags based on string hash
  static TagColors getTagColors(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final hash = StringUtils.stringToHash(tag);

    // Use different parts of hash for different properties
    final hue = ((hash & 0xFF) * 360 / 255).toDouble();
    final satVariation = (hash >> 8) & 0xFF;
    final lightVariation = (hash >> 16) & 0xFF;

    final double saturation;
    final double lightness;

    if (brightness == Brightness.light) {
      saturation = 0.25 + (satVariation % 30) / 100; // 0.25 to 0.55
      lightness = 0.85 + (lightVariation % 12) / 100; // 0.85 to 0.97
    } else {
      saturation = 0.35 + (satVariation % 40) / 100; // 0.35 to 0.75
      lightness = 0.12 + (lightVariation % 18) / 100; // 0.12 to 0.30
    }

    final backgroundColor = HSLColor.fromAHSL(
      1.0,
      hue,
      saturation,
      lightness,
    ).toColor();

    // Smart text color selection
    Color textColor;
    if (brightness == Brightness.light) {
      textColor = colorScheme.onSurface;
    } else {
      textColor = colorScheme.surface;
    }

    return TagColors(
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderColor: textColor.withValues(alpha: 0.7),
    );
  }

  /// Gets contrasting text color for given background
  static Color getContrastingTextColor(
    BuildContext context,
    Color backgroundColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final luminance = backgroundColor.computeLuminance();

    return luminance > 0.5 ? colorScheme.onSurface : colorScheme.surface;
  }
}

class TagColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const TagColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
