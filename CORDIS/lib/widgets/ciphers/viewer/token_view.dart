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
    return Consumer2<LayoutSettingsProvider, TranspositionProvider>(
      builder: (context, laySet, trans, child) {
        final content = _buildContentWidgets(context, laySet);
        return SizedBox(
          height: content.contentHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: content.tokens,
          ),
        );

      },
    );
  }

  ContentTokenized _buildContentWidgets(
    BuildContext context,
    LayoutSettingsProvider laySet,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final lyricStyle = TextStyle(
      fontSize: laySet.fontSize,
      color: colorScheme.onSurface,
      fontFamily: laySet.fontFamily,
    );
    final chordStyle = TextStyle(
      fontSize: laySet.fontSize,
      color: colorScheme.primary,
    );

    final tokens = _tokenizer.tokenize(chordPro);

    final filteredTokens = _tokenizer.filterTokens(
      tokens,
      laySet.contentFilters,
    );

    final organizedTokens = _tokenizer.organize(filteredTokens);

    final viewWidgets = _tokenizer.buildViewWidgets(
      organizedTokens,
      filteredTokens,
      lyricStyle,
      chordStyle,
    );

    final content = _tokenizer.positionWidgets(context, viewWidgets);
    return content;
  }
}
