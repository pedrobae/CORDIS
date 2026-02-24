import 'dart:math';

import 'package:cordis/models/ui/content_token.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_token.dart';
import 'package:flutter/material.dart';

final double _fontSize = 18;

/// Helper class to track a widget along with its pre-calculated width
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

/// Helper class to track positioned widgets with their associated WidgetWithSize info
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

class TokenizationService {
  /// Tokenizes the given content string into a list of ContentTokens.
  /// Creates preceding chord target tokens in lines where there are no spaces before lyrics.
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
          return ''; // Preceding chord targets are not represented in the content string
      }
    }).join();
  }

  /// Measures text width with caching to avoid recalculating TextPainter
  double measureTextWidth(
    String text,
    String fontFamily, {
    Map<String, double>? cache,
  }) {
    cache ??= {};
    final key = '$text|$fontFamily';
    return cache.putIfAbsent(key, () {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: _fontSize, fontFamily: fontFamily),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      return textPainter.width;
    });
  }

  /// Builds token widgets with drag-and-drop capabilities, with their sizes pre-calculated.
  List<List<List<WidgetWithSize>>> buildContentWidgets(
    List<List<List<ContentToken>>> contentTokens,
    List<ContentToken> tokens,
    String fontFamily,
    Color contentColor,
    Color lyricColor,
    VoidCallback toggleDrag,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, ContentToken, int) onAddPrecedingChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final widthCache = <String, double>{};

    /// Build all token widgets, and calculate their sizes for positioning
    final contentWidgets = <List<List<WidgetWithSize>>>[];
    int position = 0;
    for (var line in contentTokens) {
      final lineWidgets = <List<WidgetWithSize>>[];
      for (var word in line) {
        final wordWidgets = <WidgetWithSize>[];
        for (var token in word) {
          switch (token.type) {
            case TokenType.precedingChordTarget:
              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildPrecedingChordDragTarget(
                    line,
                    tokens,
                    token,
                    position,
                    fontFamily,
                    contentColor,
                    onAddPrecedingChord,
                    onRemoveChord,
                    isEnabled,
                  ),
                  width: 24,
                  type: TokenType.precedingChordTarget,
                ),
              );
              break;
            case TokenType.chord:
              final chordWidth =
                  measureTextWidth(token.text, fontFamily, cache: widthCache) +
                  20; // Add ChordToken padding

              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildDraggableChord(
                    token,
                    position,
                    contentColor,
                    fontFamily,
                    toggleDrag,
                    isEnabled,
                  ),
                  width: chordWidth,
                  type: TokenType.chord,
                ),
              );
              break;
            case TokenType.lyric:
              final lyricWidth = measureTextWidth(
                token.text,
                fontFamily,
                cache: widthCache,
              );

              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildLyricDragTarget(
                    line,
                    tokens,
                    token,
                    position,
                    contentColor,
                    lyricColor,
                    fontFamily,
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
              final tokenWidth = measureTextWidth(
                ' ',
                fontFamily,
                cache: widthCache,
              );

              wordWidgets.add(
                WidgetWithSize(
                  widget: _buildSpaceDragTarget(
                    line,
                    tokens,
                    token,
                    position,
                    tokenWidth,
                    fontFamily,
                    contentColor,
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
          }
          position++;
        }
        if (wordWidgets.isNotEmpty) {
          lineWidgets.add(List.from(wordWidgets));
          wordWidgets.clear();
        }
      }
      if (lineWidgets.isNotEmpty) {
        contentWidgets.add(List.from(lineWidgets));
        lineWidgets.clear();
      }
    }
    return contentWidgets;
  }

  /// Organizes the given list of WidgetWithSize into lines and words based on TokenType.
  List<List<List<ContentToken>>> organize(List<ContentToken> widgetsWithSize) {
    // Organize widgets by lines and words
    final wordWidgetsWithSize = <ContentToken>[];
    final lineWidgetsWithSize = <List<ContentToken>>[];
    final contentWidgetsWithSize = <List<List<ContentToken>>>[];
    for (var widgetWithSize in widgetsWithSize) {
      switch (widgetWithSize.type) {
        case TokenType.newline:
          // End of line
          if (wordWidgetsWithSize.isNotEmpty) {
            lineWidgetsWithSize.add(
              List.from(wordWidgetsWithSize),
            ); // Add word to line
            wordWidgetsWithSize.clear();
          }

          lineWidgetsWithSize.add([
            widgetWithSize,
          ]); // Add newline as separate word

          contentWidgetsWithSize.add(
            List.from(lineWidgetsWithSize),
          ); // Add line to content
          lineWidgetsWithSize.clear();
          break;

        case TokenType.space:
          // End of word
          if (wordWidgetsWithSize.isNotEmpty) {
            lineWidgetsWithSize.add(
              List.from(wordWidgetsWithSize),
            ); // Add word to line
            wordWidgetsWithSize.clear();
          }

          lineWidgetsWithSize.add([
            widgetWithSize,
          ]); // Add space as separate word
          break;

        case TokenType.lyric:
        case TokenType.chord:
        case TokenType.precedingChordTarget:
          // Part of a word
          wordWidgetsWithSize.add(widgetWithSize);
      }
    }
    // Add any remaining widgets
    if (wordWidgetsWithSize.isNotEmpty) {
      lineWidgetsWithSize.add(List.from(wordWidgetsWithSize));
      wordWidgetsWithSize.clear();
    }
    if (lineWidgetsWithSize.isNotEmpty) {
      contentWidgetsWithSize.add(List.from(lineWidgetsWithSize));
      lineWidgetsWithSize.clear();
    }
    return contentWidgetsWithSize;
  }

  double _calculatePrecedingChordOffset(
    List<List<List<WidgetWithSize>>> lines,
    double letterSpacing,
  ) {
    double precedingOffset = 0;
    for (var lineWidgets in lines) {
      double linePrecedingOffset = 0;
      for (var wordWidgets in lineWidgets) {
        if (wordWidgets.isNotEmpty && wordWidgets[0].type != TokenType.lyric) {
          linePrecedingOffset = wordWidgets[0].width + letterSpacing;
          break;
        }
      }
      if (linePrecedingOffset > precedingOffset) {
        precedingOffset = linePrecedingOffset;
      }
    }
    return precedingOffset;
  }

  /// Positions the given list of WidgetWithSize into a List of Positioned widgets, with content height pre calculated.
  /// handling line breaks and spacing.
  ContentTokenized positionWidgets(
    BuildContext context,
    List<List<List<WidgetWithSize>>> contentWidgets, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    // Check if there is any preceding chord target in the content
    // Used to offset initial X position
    final precedingOffset = _calculatePrecedingChordOffset(
      contentWidgets,
      letterSpacing,
    );

    // Account for vertical padding (3 + 4 top + bottom from ChordToken)
    final double chordHeight = _fontSize + 7;
    // Account for padding (16, 16, 8 left + 8, 16, 16 right)
    final double maxWidth = MediaQuery.of(context).size.width - 80;

    final double lineHeight = chordHeight + lineSpacing + _fontSize;

    int viewLineIndex = 0; // Last lyric line number

    final tokenWidgets = <Positioned>[];
    for (var lineWidgets in contentWidgets) {
      double chordX = 0; // End of the last chord positioned
      double lyricsX = 0; // End of the last lyric/space positioned
      bool foundLyricInLine = false;

      for (var wordWidgets in lineWidgets) {
        bool lineBroke = false;
        List<_PositionedWithRef> tempWordWidgets = [];
        for (var widgetWithSize in wordWidgets) {
          switch (widgetWithSize.type) {
            case TokenType.chord:
              // Position chord above max (currentX chordX)
              final xCoord = max(chordX, lyricsX);
              tempWordWidgets.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: xCoord,
                    top: viewLineIndex * lineHeight,
                    child: widgetWithSize.widget,
                  ),
                  ref: widgetWithSize,
                ),
              );

              chordX = xCoord + widgetWithSize.width + letterSpacing;

              if (chordX > maxWidth) {
                lineBroke = true;
              }
              break;

            case TokenType.lyric:
              if (!foundLyricInLine) {
                foundLyricInLine = true;
                // Set lyricsX to account for preceding chord targets
                lyricsX = precedingOffset;
              }

              // Position lyric
              tempWordWidgets.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: lyricsX,
                    top: (viewLineIndex * lineHeight) + chordHeight,
                    child: widgetWithSize.widget,
                  ),
                  ref: widgetWithSize,
                ),
              );
              lyricsX += widgetWithSize.width + letterSpacing;

              if (lyricsX > maxWidth) {
                lineBroke = true;
              }
              break;
            case TokenType.space:
              // Check if adding the space would break the line
              if (widgetWithSize.width + lyricsX > maxWidth) {
                // Skip adding the space if it breaks the line
                lineBroke = true;
                break;
              }

              tempWordWidgets.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: lyricsX,
                    top: (viewLineIndex * lineHeight) + chordHeight,
                    child: widgetWithSize.widget,
                  ),
                  ref: widgetWithSize,
                ),
              );
              lyricsX += widgetWithSize.width + letterSpacing;
              break;

            case TokenType.newline:
              lineBroke = true;
              foundLyricInLine = false;
              break;

            case TokenType.precedingChordTarget:
              if (foundLyricInLine) {
                throw Exception('Preceding chord target found after lyric');
              }
              // Position preceding chord target
              tempWordWidgets.add(
                _PositionedWithRef(
                  positioned: Positioned(
                    left: precedingOffset - widgetWithSize.width,
                    top: viewLineIndex * lineHeight + chordHeight,
                    child: widgetWithSize.widget,
                  ),
                  ref: widgetWithSize,
                ),
              );
              lyricsX = precedingOffset;
              break;
          }
        }
        // If line broke reposition, else add normally
        if (lineBroke) {
          viewLineIndex++;
          chordX = 0;
          lyricsX = precedingOffset;
          for (var posWithRef in tempWordWidgets) {
            final widgetWithSize = posWithRef.ref;
            switch (widgetWithSize.type) {
              case TokenType.chord:
                tokenWidgets.add(
                  Positioned(
                    left: max(chordX, lyricsX),
                    top: viewLineIndex * lineHeight,
                    child: widgetWithSize.widget,
                  ),
                );
                chordX =
                    max(chordX, lyricsX) + widgetWithSize.width + letterSpacing;
                break;
              case TokenType.lyric:
                tokenWidgets.add(
                  Positioned(
                    left: lyricsX,
                    top: (viewLineIndex * lineHeight) + chordHeight,
                    child: widgetWithSize.widget,
                  ),
                );
                lyricsX += widgetWithSize.width + letterSpacing;
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
                // This is now valid after line breaks with foundLyricInLine reset
                foundLyricInLine = false;
                tokenWidgets.add(
                  Positioned(
                    left: precedingOffset - widgetWithSize.width,
                    top: viewLineIndex * lineHeight + chordHeight,
                    child: widgetWithSize.widget,
                  ),
                );
                lyricsX = precedingOffset;
                break;
            }
          }
        } else {
          tokenWidgets.addAll(tempWordWidgets.map((e) => e.positioned));
        }
      }
    }

    return ContentTokenized(
      tokenWidgets,
      (viewLineIndex + 1) * // +1 to account for last line (index starts at 0)
          lineHeight,
    );
  }

  // ====== Widget Builders ======
  Widget _buildDraggableChord(
    ContentToken token,
    int position,
    Color contentColor,
    String fontFamily,
    VoidCallback toggleDrag,
    bool isEnabled,
  ) {
    // Assign position to token for reference
    token.position = position;

    // ChordTokens
    final chordWidget = ChordToken(
      token: token,
      sectionColor: contentColor,
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: Colors.white,
        fontFamily: fontFamily,
      ),
    );

    final dimChordWidget = ChordToken(
      token: token,
      sectionColor: contentColor.withValues(alpha: .5),
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: Colors.white,
        fontFamily: fontFamily,
      ),
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
    List<List<ContentToken>> lineTokens,
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    String fontFamily,
    Color contentColor,
    Function(List<ContentToken>, ContentToken, int) onAddPrecedingChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final dragTargetChild = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: BorderDirectional(
          bottom: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
      ),
    );

    return isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onAddPrecedingChord(tokens, details.data, position);
              if (details.data.position != null) {
                int index = details.data.position!;
                if (index > position) {
                  index += 2; // Adjust for two insertions (Chord + Space)
                }
                onRemoveChord(tokens, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  context,
                  dragTargetChild,
                  candidateData.first!,
                  token,
                  lineTokens,
                  fontFamily,
                  contentColor,
                );
              }
              return dragTargetChild;
            },
          )
        : dragTargetChild;
  }

  Widget _buildLyricDragTarget(
    List<List<ContentToken>> lineTokens,
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    Color contentColor,
    Color lyricColor,
    String fontFamily,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final dragTargetChild = Text(
      token.text,
      style: TextStyle(
        fontSize: _fontSize,
        color: lyricColor,
        fontFamily: fontFamily,
      ),
    );

    return isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onAddChord(tokens, details.data, position);
              if (details.data.position != null) {
                int index = details.data.position!;
                if (index > position) {
                  index++;
                }
                onRemoveChord(tokens, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  context,
                  dragTargetChild,
                  candidateData.first!,
                  token,
                  lineTokens,
                  fontFamily,
                  contentColor,
                );
              }
              return dragTargetChild;
            },
          )
        : dragTargetChild;
  }

  Widget _buildSpaceDragTarget(
    List<List<ContentToken>> lineTokens,
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    double width,
    String fontFamily,
    Color contentColor,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    final dragTargetChild = SizedBox(width: width, height: 24);

    return isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onAddChord(tokens, details.data, position);
              if (details.data.position != null) {
                int index = details.data.position!;
                if (index > position) {
                  index++;
                }
                onRemoveChord(tokens, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  context,
                  dragTargetChild,
                  candidateData.first!,
                  token,
                  lineTokens,
                  fontFamily,
                  contentColor,
                );
              }
              return dragTargetChild;
            },
          )
        : dragTargetChild;
  }

  /// Builds the feedback widget shown when dragging a chord over a valid target,
  /// Showing the chord above the target, with the close by tokens,
  /// Similar to what is shown when selecting text in a text editor, to give better context of where the chord will be dropped.
  Widget _buildDragTargetFeedback(
    BuildContext context,
    Widget dragTargetChild,
    ContentToken draggedChord,
    ContentToken draggedToToken,
    List<List<ContentToken>> lineTokens,
    String fontFamily,
    Color contentColor,
  ) {
    final lyricTokens = lineTokens
        .expand((word) => word)
        .where(
          (token) =>
              token.type == TokenType.lyric ||
              token.type == TokenType.space ||
              token.type == TokenType.precedingChordTarget,
        )
        .toList();

    // GET LYRICTOKENS CUTOUT (5 BEFORE AND 10 AFTER DRAGGED TO TOKEN)
    // If the dragged to token is at the start or end of the line,
    // Adjust the cutout accordingly to show more tokens on the other side,
    // To ensure there are always 10 tokens shown in the cutout when possible
    int draggedToIndex = lyricTokens.indexWhere(
      (token) => token == draggedToToken,
    );
    final int startIndex = max(0, draggedToIndex - 5);
    final int endIndex = min(lyricTokens.length, draggedToIndex + 10);
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
              textStyle: TextStyle(
                fontSize: _fontSize,
                color: Colors.white,
                fontFamily: fontFamily,
              ),
            ),
          ),
        );
      }
      positionedWidgets.add(
        Positioned(
          left: xOffset,
          top: _fontSize + 10, // Chord Token offset
          child: Text(
            token.text,
            style: TextStyle(
              fontSize: _fontSize,
              color: Colors.black87,
              fontFamily: fontFamily,
            ),
          ),
        ),
      );
      xOffset +=
          measureTextWidth(token.text, fontFamily) + 1; // Add letter spacing
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
          top: -(_fontSize * 3),
          left: leftOffset,
          child: Container(
            height: 2 * (_fontSize + 8), // Height to fit the chord and lyrics
            width: 130,
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
}
