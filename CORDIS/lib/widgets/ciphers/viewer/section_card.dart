import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/widgets/ciphers/viewer/chordpro_view.dart';
import 'package:cordis/providers/layout_settings_provider.dart';

class SectionCard extends StatelessWidget {
  final String sectionCode;
  final String sectionType;
  final String sectionText;
  final Color sectionColor;

  const SectionCard({
    super.key,
    required this.sectionType,
    required this.sectionCode,
    required this.sectionText,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutSettingsProvider>(
      builder: (context, layoutSettingsProvider, child) {
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;

        // Measure section code width on the correct style
        final textPainter = TextPainter(
          text: TextSpan(
            text: sectionCode,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.surface,
              fontSize: layoutSettingsProvider.fontSize,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final sectionCodeWidth =
            textPainter.size.width + 16; // 8 padding each side

        if (sectionText.trim().isEmpty) {
          return SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              // LABEL
              Row(
                spacing: 8,
                children: [
                  Container(
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
                        fontSize: layoutSettingsProvider.fontSize - 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    sectionType.isNotEmpty
                        ? sectionType[0].toUpperCase() +
                              sectionType.substring(1)
                        : sectionType,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: layoutSettingsProvider.fontSize - 2,
                    ),
                  ),
                ],
              ),
              ChordProView(
                chordPro: sectionText,
                isAnnotation: sectionCode == 'N',
              ),
            ],
          ),
        );
      },
    );
  }
}
