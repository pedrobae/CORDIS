import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/services/tokenization_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TokenView extends StatelessWidget {
  final String chordPro;

  const TokenView({super.key, required this.chordPro});

  static const _tokenizer = TokenizationService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<LayoutSettingsProvider, TranspositionProvider>(
      builder: (context, laySet, trans, child) {
        final tokens = _tokenizer.tokenize(chordPro);

        for (var token in tokens) {
          if (token.type == TokenType.chord) {
            token.text = trans.transposeChord(token.text);
          }
        }

        final filteredTokens = _tokenizer.filterTokens(
          tokens,
          laySet.contentFilters,
        );

        final organizedTokens = _tokenizer.organize(filteredTokens);

        final viewWidgets = _tokenizer.buildViewWidgets(
          organizedTokens,
          filteredTokens,
          laySet.lyricTextStyle,
          laySet.chordTextStyle(colorScheme.primary),
        );

        final content = _tokenizer.positionWidgets(
          context,
          viewWidgets,
          underLineColor: colorScheme.onSurface,
          chordStyle: laySet.chordTextStyle(colorScheme.primary),
          lyricStyle: laySet.lyricTextStyle,
        );

        return SizedBox(
          height: content.contentHeight,
          child: Stack(clipBehavior: Clip.none, children: content.tokens),
        );
      },
    );
  }
}
