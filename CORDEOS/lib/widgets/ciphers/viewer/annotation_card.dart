import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnnotationCard extends StatelessWidget {
  final String sectionText;
  final String sectionType;

  const AnnotationCard({
    super.key,
    required this.sectionText,
    required this.sectionType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Selector<
      LayoutSetProvider,
      ({double fontSize, double cardWidthMult, TextStyle lyricStyle})
    >(
      selector: (context, laySet) => (
        fontSize: laySet.fontSize,
        cardWidthMult: laySet.cardWidthMult,
        lyricStyle: laySet.lyricStyle,
      ),
      builder: (context, s, child) {
        if (sectionText.trim().isEmpty) {
          return SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth * s.cardWidthMult,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(0),
                border: BoxBorder.fromLTRB(
                  left: BorderSide(color: colorScheme.primary, width: 6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  // LABEL
                  Text(
                    sectionType.isNotEmpty
                        ? sectionType[0].toUpperCase() +
                              sectionType.substring(1)
                        : sectionType,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: s.fontSize * 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // CONTENT
                  Text(sectionText, style: s.lyricStyle),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
