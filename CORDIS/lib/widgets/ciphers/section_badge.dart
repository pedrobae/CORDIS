import 'dart:math';

import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionBadge extends StatelessWidget {
  final String sectionCode;
  final Color sectionColor;

  const SectionBadge({
    super.key,
    required this.sectionCode,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final lsp = context.read<LayoutSettingsProvider>();

    // Measure section code width on the correct style
    final textPainter = TextPainter(
      text: TextSpan(
        text: sectionCode,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.surface,
          fontSize: lsp.fontSize,
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
        color: sectionColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        sectionCode,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.surface,
          fontSize: lsp.fontSize - 4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
