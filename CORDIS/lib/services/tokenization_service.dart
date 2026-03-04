import 'dart:math';

import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_token.dart';
import 'package:flutter/material.dart';

class TokenizationConstants {
  static const double precedingTargetWidth = 24.0;
  static const double chordPadding = 20.0;
  static const int dragFeedbackTokensBefore = 5;
  static const int dragFeedbackTokensAfter = 10;
  static const double dragFeedbackCutoutWidth = 130.0;
  static const double defaultFallbackWidth = 8.0;
  static const double chordEditModePadding = 7.0;
  static const double contentPaddingEdit = 80.0;
  static const double contentPaddingView = 64.0;
}

class ContentToken {
  String text;
  final TokenType type;
  int? position;

  ContentToken({required this.text, required this.type, this.position});
}

enum TokenType {
  chord,
  lyric,
  space,
  newline,
  precedingChordTarget, // Token that exists when editing
  underline, // Underscore widget used to stretch a word when a chord cant fit
}

class Measurements {
  final double width;
  final double height;
  final double baseline;
  final double size;

  Measurements({
    required this.width,
    required this.height,
    required this.baseline,
    required this.size,
  });
}

class WidgetWithSize {
  final Widget widget;
  final double width;
  final TokenType type;

  WidgetWithSize({
    required this.widget,
    required this.width,
    required this.type,
  });
}

class _PositionedWithRef {
  final Positioned positioned;
  final WidgetWithSize ref;

  _PositionedWithRef({required this.positioned, required this.ref});
}

class ContentTokenized {
  final List<Positioned> tokens;
  final double contentHeight;

  ContentTokenized(this.tokens, this.contentHeight);
}

class TokenWord {
  final List<ContentToken> tokens;

  TokenWord(this.tokens);

  bool get isEmpty => tokens.isEmpty;
  bool get isNotEmpty => tokens.isNotEmpty;
}

/// Represents a line as a collection of words
class TokenLine {
  final List<TokenWord> words;

  TokenLine(this.words);

  bool get isEmpty => words.isEmpty;
  bool get isNotEmpty => words.isNotEmpty;

  /// Converts to nested list for backwards compatibility
  List<List<ContentToken>> toNestedList() {
    return words.map((word) => word.tokens).toList();
  }
}

/// Represents organized content as a collection of lines
class OrganizedTokens {
  final List<TokenLine> lines;

  OrganizedTokens(this.lines);

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
}

class WidgetWord {
  final List<WidgetWithSize> widgets;

  WidgetWord(this.widgets);

  bool get isEmpty => widgets.isEmpty;
  bool get isNotEmpty => widgets.isNotEmpty;
}

class WidgetLine {
  final List<WidgetWord> words;

  WidgetLine(this.words);

  bool get isEmpty => words.isEmpty;
  bool get isNotEmpty => words.isNotEmpty;
}

class OrganizedWidgets {
  final List<WidgetLine> lines;

  OrganizedWidgets(this.lines);

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
}

class TokenizationService {
  const TokenizationService();

  /// Tokenizes the given content string into a list of ContentTokens.
  ///
  /// Parses ChordPro-style content with chords in brackets [Am], [F#m7],.
  /// Creates preceding chord target tokens in lines where there are no spaces before lyrics,
  /// allowing chords to be positioned before the first lyric character.
  ///
  /// Example:
  /// ```dart
  /// final service = TokenizationService();
  /// final tokens = service.tokenize('[Am]Amazing [F]grace\nHow [C]sweet');
  /// ```
  List<ContentToken> tokenize(String content) {
    if (content.isEmpty) {
      return [];
    }

    final List<ContentToken> tokens = [];
    final List<ContentToken> lineTokens = [];
    bool spaceBeforeLyrics = false;
    bool foundLyricInLine = false;
    for (int index = 0; index < content.length; index++) {
      final char = content[index];
      if (char == '\n') {
        if (lineTokens.isEmpty) {
          // Handle empty lines
          tokens.add(ContentToken(type: TokenType.newline, text: char));
          continue;
        }

        lineTokens.add(ContentToken(type: TokenType.newline, text: char));

        if (!spaceBeforeLyrics) {
          // Insert preceding chord target tokens at the starts of lines
          lineTokens.insert(
            0,
            ContentToken(type: TokenType.precedingChordTarget, text: ''),
          );
        }

        // Add Line and Reset for the next line
        spaceBeforeLyrics = false;
        foundLyricInLine = false;
        tokens.addAll(lineTokens);
        lineTokens.clear();
      } else if (char == ' ' || char == '\t') {
        if (!foundLyricInLine) {
          spaceBeforeLyrics = true;
        }
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
      } else if (char == '[') {
        index++; // Move past the '['
        String chordText = '';
        while (index < content.length && content[index] != ']') {
          chordText += content[index];
          index++;
        }
        lineTokens.add(ContentToken(type: TokenType.chord, text: chordText));
      } else {
        foundLyricInLine = true;
        lineTokens.add(ContentToken(type: TokenType.lyric, text: char));
      }
    }

    if (lineTokens.isNotEmpty) {
      if (!spaceBeforeLyrics) {
        // Insert preceding chord target tokens at the starts of lines
        lineTokens.insert(
          0,
          ContentToken(type: TokenType.precedingChordTarget, text: ''),
        );
      }
      tokens.addAll(lineTokens);
    }

    if (tokens.isNotEmpty && tokens.last.type == TokenType.newline) {
      tokens.removeLast();
    }
    return tokens;
  }

  /// Reconstructs the content string from a list of ContentTokens.
  ///
  /// Converts tokens back to ChordPro format with chords in brackets.
  /// Purely visual tokens (precedingChordTarget, underline) are excluded.
  String reconstructContent(List<ContentToken> tokens) {
    return tokens.map((token) {
      switch (token.type) {
        case TokenType.chord:
          return '[${token.text}]';
        case TokenType.lyric:
        case TokenType.space:
        case TokenType.newline:
          return token.text;
        case TokenType.precedingChordTarget:
        case TokenType.underline:
          break; // Purely visual tokens
      }
    }).join();
  }

  /// Measures text dimensions.
  ///
  /// Cache key includes all relevant style properties (fontFamily, fontSize, fontWeight, letterSpacing)
  /// to avoid cache collisions between different text styles.
  ///
  /// Returns [Measurements] containing width, height, baseline, and size.
  Measurements measureText(
    String text,
    TextStyle style, {
    Map<String, Measurements>? cache,
  }) {
    cache ??= {};
    final key =
        '$text|${style.fontFamily}|${style.fontSize}|'
        '${style.fontWeight?.index}|${style.letterSpacing}';
    return cache.putIfAbsent(key, () {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final measurements = Measurements(
        width: textPainter.width,
        height: textPainter.height,
        baseline: textPainter.computeDistanceToActualBaseline(
          TextBaseline.alphabetic,
        ),
        size: style.fontSize ?? 14.0,
      );

      return measurements;
    });
  }

  /// Builds widgets for viewing mode, with their sizes pre-calculated.
  ///
  /// Creates read-only text widgets for chords and lyrics.
  /// Returns organized structure with lines -> words -> widgets.
  /// Widget sizes are measured and cached for efficient positioning.
  OrganizedWidgets buildViewWidgets(
    OrganizedTokens organizedTokens,
    List<ContentToken> tokens,
    TextStyle lyricStyle,
    TextStyle chordStyle,
  ) {
    final lines = <WidgetLine>[];

    final widthCache = <String, Measurements>{};

    for (var line in organizedTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <WidgetWithSize>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.chord:
              final textWidth = measureText(
                token.text,
                chordStyle,
                cache: widthCache,
              ).width;
              wordWidgets.add(
                WidgetWithSize(
                  widget: Text(token.text, style: chordStyle),
                  width: textWidth,
                  type: TokenType.chord,
                ),
              );
              break;
            case TokenType.lyric:
              final textWidth = measureText(
                token.text,
                lyricStyle,
                cache: widthCache,
              ).width;

              wordWidgets.add(
                WidgetWithSize(
                  widget: Text(token.text, style: lyricStyle),
                  width: textWidth,
                  type: TokenType.lyric,
                ),
              );
              break;
            case TokenType.space:
              final textWidth = measureText(
                ' ',
                lyricStyle,
                cache: widthCache,
              ).width;

              wordWidgets.add(
                WidgetWithSize(
                  widget: Text(' ', style: lyricStyle),
                  width: textWidth,
                  type: TokenType.space,
                ),
              );
              break;
            case TokenType.newline:
              // NEW LINE TOKENS INDICATE LINE BREAKS
              wordWidgets.add(
                WidgetWithSize(
                  widget: SizedBox.shrink(),
                  width: 0,
                  type: TokenType.newline,
                ),
              );
              break;
            case TokenType.precedingChordTarget:
            case TokenType.underline:
              break;
          }
        }
        if (wordWidgets.isNotEmpty) {
          words.add(WidgetWord(wordWidgets));
        }
      }
      if (words.isNotEmpty) {
        lines.add(WidgetLine(words));
      }
    }

    return OrganizedWidgets(lines);
  }

  /// Builds widgets with drag-and-drop capabilities for editing mode.
  ///
  /// Creates interactive widgets:
  /// - Draggable chord widgets that can be moved
  /// - Drop target widgets for lyrics and spaces
  /// - Preceding chord targets for line-start positioning
  ///
  /// Returns organized structure with lines -> words -> widgets.
  OrganizedWidgets buildEditWidgets(
    OrganizedTokens contentTokens,
    List<ContentToken> tokens,
    TextStyle chordStyle,
    TextStyle lyricStyle,
    Color contentColor,
    VoidCallback toggleDrag,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, ContentToken, int) onAddPrecedingChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final widthCache = <String, Measurements>{};

    /// Build all token widgets, and calculate their sizes for positioning
    final lines = <WidgetLine>[];
    int position = 0;
    for (var line in contentTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <WidgetWithSize>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.precedingChordTarget:
              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildPrecedingChordDragTarget(
                    line,
                    tokens,
                    token,
                    position,
                    lyricStyle,
                    chordStyle,
                    measureText('teste', lyricStyle, cache: widthCache),
                    contentColor,
                    onAddPrecedingChord,
                    onRemoveChord,
                    isEnabled,
                  ),
                  width: TokenizationConstants.precedingTargetWidth,
                  type: TokenType.precedingChordTarget,
                ),
              );
              break;
            case TokenType.chord:
              final chordWidth =
                  measureText(token.text, chordStyle, cache: widthCache).width +
                  TokenizationConstants.chordPadding;

              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildDraggableChord(
                    token,
                    position,
                    contentColor,
                    chordStyle,
                    toggleDrag,
                    isEnabled,
                  ),
                  width: chordWidth,
                  type: TokenType.chord,
                ),
              );
              break;
            case TokenType.lyric:
              final lyricWidth = measureText(
                token.text,
                lyricStyle,
                cache: widthCache,
              ).width;

              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildLyricDragTarget(
                    line,
                    tokens,
                    token,
                    position,
                    contentColor,
                    lyricStyle,
                    chordStyle,
                    onAddChord,
                    onRemoveChord,
                    isEnabled,
                  ),
                  width: lyricWidth,
                  type: TokenType.lyric,
                ),
              );
              break;

            case TokenType.space:
              final tokenWidth = measureText(
                ' ',
                lyricStyle,
                cache: widthCache,
              ).width;

              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildSpaceDragTarget(
                    line,
                    tokens,
                    token,
                    position,
                    tokenWidth,
                    contentColor,
                    lyricStyle,
                    chordStyle,
                    onAddChord,
                    onRemoveChord,
                    isEnabled,
                  ),
                  width: tokenWidth,
                  type: TokenType.space,
                ),
              );
              break;

            case TokenType.newline:
              // Newline tokens dont have fixed width
              wordWidgets.add(
                WidgetWithSize(
                  widget: SizedBox.shrink(),
                  width: 0,
                  type: TokenType.newline,
                ),
              );
              break;
            case TokenType.underline:
              break;
          }
          position++;
        }
        if (wordWidgets.isNotEmpty) {
          words.add(WidgetWord(wordWidgets));
        }
      }
      if (words.isNotEmpty) {
        lines.add(WidgetLine(words));
      }
    }
    return OrganizedWidgets(lines);
  }

  /// Filters tokens based on content filter settings.
  ///
  /// Allows showing/hiding chords and lyrics independently.
  /// Visual tokens (newline, underline, precedingChordTarget) are shown if any content is visible.
  List<ContentToken> filterTokens(
    List<ContentToken> tokens,
    Map<ContentFilter, bool> contentFilters,
  ) {
    return tokens.where((token) {
      switch (token.type) {
        case TokenType.chord:
          return contentFilters[ContentFilter.chords]!;
        case TokenType.space:
        case TokenType.lyric:
          return contentFilters[ContentFilter.lyrics]!;
        case TokenType.newline:
        case TokenType.underline:
        case TokenType.precedingChordTarget:
          // Returns true if any content is shown
          return contentFilters[ContentFilter.chords]! ||
              contentFilters[ContentFilter.lyrics]!;
      }
    }).toList();
  }

  /// Organizes tokens into a hierarchical structure: lines -> words -> tokens.
  ///
  /// Logic:
  /// - Newline tokens end the current line
  /// - Space tokens end the current word
  /// - Lyric, chord, and precedingChordTarget tokens are part of words
  ///
  /// Returns [OrganizedTokens] with clear hierarchical structure.
  OrganizedTokens organize(List<ContentToken> tokens) {
    // Organize tokens by lines and words
    final currentWord = <ContentToken>[];
    final currentLine = <TokenWord>[];
    final lines = <TokenLine>[];
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.newline:
          // End of line
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }

          // Add newline as separate word
          currentLine.add(TokenWord([token]));

          // Add line to content
          lines.add(TokenLine(List.from(currentLine)));
          currentLine.clear();
          break;

        case TokenType.space:
          // End of word
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }

          // Add space as separate word
          currentLine.add(TokenWord([token]));
          break;

        case TokenType.lyric:
        case TokenType.chord:
        case TokenType.precedingChordTarget:
          // Part of a word
          currentWord.add(token);
        case TokenType.underline:
          break;
      }
    }
    // Add any remaining tokens
    if (currentWord.isNotEmpty) {
      currentLine.add(TokenWord(currentWord));
    }
    if (currentLine.isNotEmpty) {
      lines.add(TokenLine(currentLine));
    }
    return OrganizedTokens(lines);
  }

  /// Calculates the offset needed for preceding chord targets.
  ///
  /// Finds the widest preceding chord target across all lines to ensure
  /// consistent alignment of line-start chords.
  double _calculatePrecedingChordOffset(
    OrganizedWidgets organizedWidgets,
    double letterSpacing,
    double precedingSpacing,
  ) {
    double precedingOffset = 0;
    for (var line in organizedWidgets.lines) {
      double linePrecedingOffset = 0;
      for (var word in line.words) {
        if (word.isNotEmpty && word.widgets[0].type != TokenType.lyric) {
          linePrecedingOffset = word.widgets[0].width + letterSpacing;
          break;
        }
      }
      if (linePrecedingOffset > precedingOffset) {
        precedingOffset = linePrecedingOffset;
      }
    }

    if (precedingOffset != 0) {
      precedingOffset += precedingSpacing;
    }
    return precedingOffset;
  }

  /// Positions organized widgets into absolute coordinates with line wrapping.
  ///
  /// Complex algorithm that:
  /// 1. Positions chords above their corresponding lyrics
  /// 2. Handles automatic line breaking when content exceeds maxWidth
  /// 3. Adds underline widgets when chords don't fit above lyrics
  /// 4. Maintains consistent spacing (chord-lyric, letter, line)
  ///
  /// Returns [ContentTokenized] with positioned widgets and total content height.
  ContentTokenized positionWidgets(
    BuildContext context,
    OrganizedWidgets contentWidgets, {
    required Color underLineColor,
    bool isEditMode = false,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    double lineSpacing = 4,
    double lineBreakSpacing = 4,
    double chordLyricSpacing = 4,
    double minChordSpacing = 4,
    double letterSpacing = 1,
    double precedingSpacing = 4,
  }) {
    Measurements chordMsr = measureText('teste', chordStyle);
    Measurements lyricMsr = measureText('teste', lyricStyle);

    final chordSize =
        chordMsr.size +
        (isEditMode ? TokenizationConstants.chordEditModePadding : 0);

    // Check if there is any preceding chord target in the content
    // Used to offset initial X position
    final precedingOffset = _calculatePrecedingChordOffset(
      contentWidgets,
      letterSpacing,
      precedingSpacing,
    );

    // Account for padding edit - (16, 16, 8 left + 8, 16, 16 right) view (16, 8 left + 16, 8 right)
    final double maxWidth =
        MediaQuery.of(context).size.width -
        (isEditMode
            ? TokenizationConstants.contentPaddingEdit
            : TokenizationConstants.contentPaddingView);

    final double lineHeight = chordSize + lyricMsr.size + chordLyricSpacing;

    double yOffset = -chordMsr.height + chordMsr.baseline; // Start with negative offset to account for chords above first line
    final tokenWidgets = <Positioned>[];
    for (var line in contentWidgets.lines) {
      double chordX = 0; // End of the last chord positioned
      double lyricsX = 0; // End of the last lyric/space positioned

      for (var word in line.words) {
        bool lineBroke = false;
        List<_PositionedWithRef> wordCache = [];
        for (var token in word.widgets) {
          switch (token.type) {
            case TokenType.chord:
              // Chord is positioned above following lyric, so we use lyricsX for chord positioning
              // But it cannot be less than chordX + minChordSpacing
              if (lyricsX < chordX) {
                // If chord cannot fit and is mid-word, add an underline widget
                if (wordCache.isNotEmpty) {
                  wordCache.add(
                    _buildUnderlineWidget(
                      chordX - lyricsX - letterSpacing,
                      lyricsX,
                      lyricMsr,
                      yOffset + chordSize + chordLyricSpacing,
                      underLineColor,
                    ),
                  );
                }
                lyricsX = chordX; // Move lyricsX to the end of the chord
              }

              wordCache.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: lyricsX,
                    top: yOffset,
                    child: token.widget,
                  ),
                  ref: token,
                ),
              );

              chordX = lyricsX + token.width + minChordSpacing;

              if (chordX > maxWidth) {
                lineBroke = true;
              }
              break;

            case TokenType.lyric:
              double xCoord = max(precedingOffset, lyricsX);
              // Position lyric
              wordCache.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: xCoord,
                    top: yOffset + chordSize + chordLyricSpacing,
                    child: token.widget,
                  ),
                  ref: token,
                ),
              );

              xCoord += token.width + letterSpacing;

              if (xCoord > maxWidth) {
                lineBroke = true;
              }
              lyricsX = xCoord;
              break;
            case TokenType.space:
              // Check if adding the space would break the line
              if (token.width + lyricsX > maxWidth) {
                // Skip adding the space if it breaks the line
                lineBroke = true;
                break;
              }

              wordCache.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: lyricsX,
                    top: yOffset + chordSize + chordLyricSpacing,
                    child: token.widget,
                  ),
                  ref: token,
                ),
              );
              lyricsX += token.width + letterSpacing;
              break;

            case TokenType.precedingChordTarget:
              // Position preceding chord target
              wordCache.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: precedingOffset - token.width,
                    top: yOffset + chordSize + chordLyricSpacing,
                    child: token.widget,
                  ),
                  ref: token,
                ),
              );
              lyricsX = precedingOffset;
              break;
            case TokenType.newline:
            case TokenType.underline:
              break;
          }
        }
        // If line broke reposition, else add normally
        if (lineBroke) {
          yOffset += lineHeight + lineBreakSpacing;

          lyricsX = precedingOffset;
          for (var posWithRef in wordCache) {
            final token = posWithRef.ref;
            switch (token.type) {
              case TokenType.chord:
                tokenWidgets.add(
                  Positioned(left: lyricsX, top: yOffset, child: token.widget),
                );
                break;
              case TokenType.underline:
              case TokenType.lyric:
                tokenWidgets.add(
                  Positioned(
                    left: lyricsX,
                    top: yOffset + chordSize + chordLyricSpacing,
                    child: token.widget,
                  ),
                );
                lyricsX += token.width + letterSpacing;
                break;
              case TokenType.space:
                throw Exception(
                  'Space found when repositioning after line break',
                );
              case TokenType.newline:
                throw Exception(
                  'Newline found when repositioning after line break',
                );
              case TokenType.precedingChordTarget:
                throw Exception(
                  'Preceding chord target found when repositioning after line break',
                );
            }
          }
        } else {
          tokenWidgets.addAll(wordCache.map((e) => e.positioned));
        }
      }
      yOffset += lineHeight + lineSpacing;
    }

    return ContentTokenized(tokenWidgets, yOffset + chordSize);
  }

  /// Checks for words exceeding maxWidth and repositions them across multiple lines.
  ///
  /// Fallback method for handling edge cases where words are too long to fit on a single line.
  /// Primarily used as a safeguard after the main positioning logic.
  ContentTokenized checkHumongousWords(
    BuildContext context,
    ContentTokenized positionedWidgets, {
    bool isEditMode = false,
    double chordHeight = 25,
    double lyricHeight = 25,
    double lineSpacing = 8,
  }) {
    // Check for humongous words that exceed maxWidth and split them into multiple lines if necessary
    final double maxWidth =
        MediaQuery.of(context).size.width -
        TokenizationConstants.contentPaddingEdit;

    if (isEditMode) {
      chordHeight += TokenizationConstants.chordEditModePadding;
    }
    final double lineHeight = chordHeight + lineSpacing + lyricHeight;

    final adjustedWidgets = <Positioned>[];
    int lineOffset = 0;
    double currentX = 0;
    for (int i = 0; i < positionedWidgets.tokens.length; i++) {
      final widget = positionedWidgets.tokens[i];
      final nextWidget = i < positionedWidgets.tokens.length - 1
          ? positionedWidgets.tokens[i + 1]
          : null;

      final widgetWidth = nextWidget != null
          ? nextWidget.left! - widget.left!
          : TokenizationConstants.defaultFallbackWidth;

      if (currentX + widgetWidth > maxWidth) {
        // Move to next line
        lineOffset++;
        currentX = 0;
      }
      if (widget.child is Draggable) {
        adjustedWidgets.add(
          Positioned(
            left: currentX,
            top: lineOffset * lineHeight + widget.top!,
            child: widget.child,
          ),
        );
      } else {
        adjustedWidgets.add(
          Positioned(
            left: currentX,
            top: lineOffset * lineHeight + widget.top!,
            child: widget.child,
          ),
        );
      }

      currentX += widgetWidth;
    }

    return ContentTokenized(
      adjustedWidgets,
      (positionedWidgets.contentHeight) + (lineOffset * lineHeight),
    );
  }

  // ====== Widget Builders ======

  /// Generic drag target builder to reduce code duplication.
  /// Wraps a child widget with DragTarget functionality if enabled.
  Widget _buildGenericDragTarget({
    required Widget child,
    required bool isEnabled,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required int position,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required Color contentColor,
    required Function(List<ContentToken>, ContentToken, int) onAccept,
    required Function(List<ContentToken>, int) onRemoveChord,
    required int Function(int originalIndex, int position)? indexAdjuster,
  }) {
    return isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onAccept(tokens, details.data, position);
              if (details.data.position != null) {
                int index = details.data.position!;
                if (indexAdjuster != null) {
                  index = indexAdjuster(index, position);
                }
                onRemoveChord(tokens, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  context,
                  child,
                  candidateData.first!,
                  token,
                  tokenLine,
                  chordStyle,
                  lyricStyle,
                  contentColor,
                );
              }
              return child;
            },
          )
        : child;
  }

  Widget _buildDraggableChord(
    ContentToken token,
    int position,
    Color contentColor,
    TextStyle chordStyle,
    VoidCallback toggleDrag,
    bool isEnabled,
  ) {
    // Assign position to token for reference
    token.position = position;

    // ChordTokens
    final chordWidget = ChordToken(
      token: token,
      sectionColor: contentColor,
      textStyle: chordStyle,
    );

    final dimChordWidget = ChordToken(
      token: token,
      sectionColor: contentColor.withValues(alpha: .5),
      textStyle: chordStyle,
    );

    // GestureDetector to handle long press to drag transition
    return isEnabled
        ? LongPressDraggable<ContentToken>(
            data: token,
            onDragStarted: toggleDrag,
            onDragEnd: (details) => toggleDrag(),
            feedback: Material(
              color: Colors.transparent,
              child: dimChordWidget,
            ),
            childWhenDragging: SizedBox.shrink(),
            child: chordWidget,
          )
        : chordWidget;
  }

  Widget _buildPrecedingChordDragTarget(
    TokenLine tokenLine,
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    TextStyle chordStyle,
    TextStyle lyricStyle,
    Measurements lyricMsr,
    Color contentColor,
    Function(List<ContentToken>, ContentToken, int) onAddPrecedingChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final dragTargetChild = SizedBox(
      height: lyricMsr.size,
      width: TokenizationConstants.precedingTargetWidth,
      child: Stack(
        children: [
          Positioned(
            top: lyricMsr.baseline,
            child: Container(
              color: Colors.grey.shade400,
              height: 2,
              width: TokenizationConstants.precedingTargetWidth,
            ),
          ),
        ],
      ),
    );

    return _buildGenericDragTarget(
      child: dragTargetChild,
      isEnabled: isEnabled,
      tokenLine: tokenLine,
      tokens: tokens,
      token: token,
      position: position,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      contentColor: contentColor,
      onAccept: onAddPrecedingChord,
      onRemoveChord: onRemoveChord,
      indexAdjuster: (originalIndex, pos) {
        // Adjust for two insertions (Chord + Space)
        return originalIndex > pos ? originalIndex + 2 : originalIndex;
      },
    );
  }

  Widget _buildLyricDragTarget(
    TokenLine tokenLine,
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    Color contentColor,
    TextStyle lyricStyle,
    TextStyle chordStyle,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final dragTargetChild = Text(token.text, style: lyricStyle);

    return _buildGenericDragTarget(
      child: dragTargetChild,
      isEnabled: isEnabled,
      tokenLine: tokenLine,
      tokens: tokens,
      token: token,
      position: position,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      contentColor: contentColor,
      onAccept: onAddChord,
      onRemoveChord: onRemoveChord,
      indexAdjuster: (originalIndex, pos) {
        return originalIndex > pos ? originalIndex + 1 : originalIndex;
      },
    );
  }

  Widget _buildSpaceDragTarget(
    TokenLine tokenLine,
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    double width,
    Color contentColor,
    TextStyle chordStyle,
    TextStyle lyricStyle,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final dragTargetChild = SizedBox(
      width: width,
      height: measureText(' ', lyricStyle).height,
    );

    return _buildGenericDragTarget(
      child: dragTargetChild,
      isEnabled: isEnabled,
      tokenLine: tokenLine,
      tokens: tokens,
      token: token,
      position: position,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      contentColor: contentColor,
      onAccept: onAddChord,
      onRemoveChord: onRemoveChord,
      indexAdjuster: (originalIndex, pos) {
        return originalIndex > pos ? originalIndex + 1 : originalIndex;
      },
    );
  }

  /// Builds the feedback widget shown when dragging a chord over a valid target,
  /// Showing the chord above the target, with the close by tokens,
  /// Similar to what is shown when selecting text in a text editor, to give better context of where the chord will be dropped.
  Widget _buildDragTargetFeedback(
    BuildContext context,
    Widget dragTargetChild,
    ContentToken draggedChord,
    ContentToken draggedToToken,
    TokenLine tokenLine,
    TextStyle chordStyle,
    TextStyle lyricStyle,
    Color contentColor,
  ) {
    final lyricTokens = [];
    for (var word in tokenLine.words) {
      for (var token in word.tokens) {
        if (token.type == TokenType.lyric ||
            token.type == TokenType.space ||
            token.type == TokenType.precedingChordTarget) {
          lyricTokens.add(token);
        }
      }
    }

    // GET LYRICTOKENS CUTOUT (configurable tokens before and after dragged token)
    // If the dragged to token is at the start or end of the line,
    // Adjust the cutout accordingly to show more tokens on the other side
    int draggedToIndex = lyricTokens.indexWhere(
      (token) => token == draggedToToken,
    );
    final int startIndex = max(
      0,
      draggedToIndex - TokenizationConstants.dragFeedbackTokensBefore,
    );
    final int endIndex = min(
      lyricTokens.length,
      draggedToIndex + TokenizationConstants.dragFeedbackTokensAfter,
    );
    final cutoutTokens = lyricTokens.sublist(startIndex, endIndex);

    // BUILD WIDGETS FOR THE CUTOUT TOKENS
    final positionedWidgets = <Positioned>[];
    double xOffset = 0.0;
    for (var token in cutoutTokens) {
      if (token == draggedToToken) {
        // Show dragged to token with the dragged chord above it
        positionedWidgets.add(
          Positioned(
            left: xOffset,
            top: 4,
            child: ChordToken(
              token: draggedChord,
              sectionColor: contentColor,
              textStyle: chordStyle,
            ),
          ),
        );
      }
      positionedWidgets.add(
        Positioned(
          left: xOffset,
          top: chordStyle.fontSize! + 10, // Chord Token offset
          child: Text(token.text, style: lyricStyle),
        ),
      );
      xOffset +=
          measureText(token.text, lyricStyle).width +
          1; // Add letter spacing to offset
    }

    // Calculate the offset to position the cutout around the dragged to token,
    // while ensuring it doesn't go off screen
    // For now simple logic to shift left if the dragged to token is in the last 3 tokens of the line,
    // and shift half left if it's in the middle, to ensure the dragged to token is always visible in the cutout

    double leftOffset = 0.0;
    if (draggedToIndex > 2) {
      leftOffset = -xOffset / 2;
    }
    if (draggedToIndex >= lyricTokens.length - 3) {
      leftOffset = -xOffset;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        dragTargetChild,
        Positioned(
          bottom: -(lyricStyle.fontSize!),
          left: leftOffset,
          child: Container(
            height: 2 * (lyricStyle.fontSize! + 8),
            width: TokenizationConstants.dragFeedbackCutoutWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface,
                  blurRadius: 8,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Stack(children: positionedWidgets),
          ),
        ),
      ],
    );
  }

  _PositionedWithRef _buildUnderlineWidget(
    double width,
    double leftOffset,
    Measurements lyricMeasurements,
    double topOffset,
    Color color,
  ) {
    final underLine = SizedBox(
      height: lyricMeasurements.size,
      width: width,
      child: Stack(
        children: [
          Positioned(
            top: lyricMeasurements.baseline,
            child: Container(width: width, height: 2, color: color),
          ),
        ],
      ),
    );

    return _PositionedWithRef(
      positioned: Positioned(
        left: leftOffset,
        top: topOffset,
        child: underLine,
      ),
      ref: WidgetWithSize(
        widget: underLine,
        width: width,
        type: TokenType.underline,
      ),
    );
  }
}
