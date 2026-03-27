import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/services/tokenization/tokenization_service.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TokenView extends StatelessWidget {
  final String chordPro;

  const TokenView({super.key, required this.chordPro});

  static const _tokenizer = TokenizationService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector2<
      LayoutSetProvider,
      TranspositionProvider,
      ({
        Function(String) transpose,
        double lineSpacing,
        double lineBreakSpacing,
        double chordLyricSpacing,
        double minChordSpacing,
        double letterSpacing,
        TextStyle chordStyle,
        TextStyle lyricStyle,
        Map<ContentFilter, bool> contentFilters,
      })
    >(
      selector: (context, laySet, trans) {
        return (
          lineSpacing: laySet.lineSpacing,
          lineBreakSpacing: laySet.lineBreakSpacing,
          chordLyricSpacing: laySet.chordLyricSpacing,
          minChordSpacing: laySet.minChordSpacing,
          letterSpacing: laySet.letterSpacing,
          transpose: trans.transposeChord,
          chordStyle: laySet.chordTextStyle(colorScheme.primary),
          lyricStyle: laySet.lyricTextStyle,
          contentFilters: laySet.contentFilters,
        );
      },
      builder: (context, s, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final content = _tokenizer.createContent(
              content: chordPro,
              posCtx: PositioningContext(
                underLineColor: colorScheme.onSurface,
                maxWidth: constraints.maxWidth,
                lineSpacing: s.lineSpacing,
                lineBreakSpacing: s.lineBreakSpacing,
                chordLyricSpacing: s.chordLyricSpacing,
                minChordSpacing: s.minChordSpacing,
                letterSpacing: s.letterSpacing,
                isEditMode: false,
              ),
              contentFilters: s.contentFilters,
              buildCtx: TokenBuildContext(
                chordStyle: s.chordStyle,
                lyricStyle: s.lyricStyle,
                contentColor: colorScheme.onSurface,
                surfaceColor: colorScheme.surface,
                onSurfaceColor: colorScheme.onSurface,
                chordTargetColor: colorScheme.surfaceTint,
                maxWidth: constraints.maxWidth,
                transposeChord: (chord) => s.transpose(chord),
                cache: {},
              ),
            );
            return SizedBox(
              height: content.contentHeight,
              child: Stack(clipBehavior: Clip.none, children: content.tokens),
            );
          },
        );
      },
    );
  }
}
