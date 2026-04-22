import 'dart:math';
import 'package:cordeos/utils/section_type.dart';
import 'package:flutter/material.dart';

class SectionBadge extends StatelessWidget {
  final SectionBadgeData sectionBadgeData;
  final bool isSelected;
  final bool isTarget;

  const SectionBadge({
    super.key,
    required this.sectionBadgeData,
    this.isSelected = false,
    this.isTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Measure section code width on the correct style
    final textPainter = TextPainter(
      text: TextSpan(
        text: sectionBadgeData.code,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.surface,
          fontSize: textTheme.labelLarge?.fontSize,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final sectionCodeWidth = textPainter.size.width + 16; // 8 padding each side

    return Container(
      width: max(28, sectionCodeWidth),
      height: 24,
      decoration: BoxDecoration(
        color: sectionBadgeData.color,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: isTarget ? colorScheme.primary : colorScheme.secondary,
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        sectionBadgeData.code,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.surface,
          fontSize: textTheme.labelLarge?.fontSize != null
              ? textTheme.labelLarge!.fontSize! - 4
              : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
