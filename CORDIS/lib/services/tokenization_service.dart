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
    if (tokens.isNotEmpty && tokens.last.type == TokenType.newline) {
      tokens.removeLast();
    }

    if (lineTokens.isNotEmpty) {
      tokens.addAll(lineTokens);
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
  List<WidgetWithSize> buildTokenWidgets(
    List<ContentToken> tokens,
    String fontFamily,
    Color contentColor,
    VoidCallback toggleDrag,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, ContentToken, int) onAddPrecedingChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    final widthCache = <String, double>{};

    /// Build all token widgets, and calculate their sizes for positioning
    List<WidgetWithSize> widgetsWithSize = [];
    int position = 0;
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.precedingChordTarget:
          widgetsWithSize.add(
            WidgetWithSize(
              widget: _buildPrecedingChordDragTarget(
                tokens,
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

          widgetsWithSize.add(
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

          widgetsWithSize.add(
            WidgetWithSize(
              widget: _buildLyricDragTarget(
                tokens,
                token,
                position,
                contentColor,
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

          widgetsWithSize.add(
            WidgetWithSize(
              widget: _buildSpaceDragTarget(
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
          widgetsWithSize.add(
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

    return widgetsWithSize;
  }

  /// Positions the given list of WidgetWithSize into a List of Positioned widgets, with content height pre calculated.
  /// handling line breaks and spacing.
  ContentTokenized positionWidgets(
    BuildContext context,
    List<WidgetWithSize> widgetsWithSize, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    // Organize widgets by lines and words
    final wordWidgetsWithSize = <WidgetWithSize>[];
    final lineWidgetsWithSize = <List<WidgetWithSize>>[];
    final contentWidgetsWithSize = <List<List<WidgetWithSize>>>[];
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

    // Check if there is any preceding chord target in the content
    // Used to offset initial X position
    double precedingOffset = 0;
    for (var lineWidgetsWithSize in contentWidgetsWithSize) {
      double linePrecedingOffset = 0;
      for (var wordWidgetsWithSize in lineWidgetsWithSize) {
        if (wordWidgetsWithSize.isNotEmpty &&
            wordWidgetsWithSize[0].type != TokenType.lyric) {
          linePrecedingOffset = wordWidgetsWithSize[0].width + letterSpacing;
          break;
        }
      }
      if (linePrecedingOffset > precedingOffset) {
        precedingOffset = linePrecedingOffset;
      }
    }

    final double chordHeight = _fontSize;
    final double lineHeight = chordHeight + lineSpacing + _fontSize;

    // Account for padding (16, 16, 8 left + 8, 16, 16 right)
    final double maxWidth = MediaQuery.of(context).size.width - 80;

    int viewLineIndex = 0; // Last lyric line number

    final tokenWidgets = <Positioned>[];
    for (var lineWidgets in contentWidgetsWithSize) {
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
              // DO NOTHING FOR NOW, TODO: TOKENIZATION populate end of line with targets
              // NewLine resets on line break processing
              lineBroke = true;
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
        // After precessing a word reposition if line broke else add to token widgets
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
                throw Exception('Preceding chord target found after lyric');
            }
          }
        } else {
          tokenWidgets.addAll(tempWordWidgets.map((e) => e.positioned));
        }
      }
      // Incrementing view line index after processing a line is handled by newLine token
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

    // GestureDetector to handle long press to drag transition
    return isEnabled
        ? Draggable<ContentToken>(
            data: token,
            onDragStarted: toggleDrag,
            onDragEnd: (details) => toggleDrag(),
            feedback: Material(
              color: Colors.transparent,
              child: ChordToken(
                token: token,
                sectionColor: contentColor.withValues(alpha: .5),
                textStyle: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.white,
                  fontFamily: fontFamily,
                ),
              ),
            ),
            childWhenDragging: SizedBox.shrink(),
            child: ChordToken(
              token: token,
              sectionColor: contentColor,
              textStyle: TextStyle(
                fontSize: _fontSize,
                color: Colors.white,
                fontFamily: fontFamily,
              ),
            ),
          )
        : ChordToken(
            token: token,
            sectionColor: contentColor,
            textStyle: TextStyle(
              fontSize: _fontSize,
              color: Colors.white,
              fontFamily: fontFamily,
            ),
          );
  }

  DragTarget<ContentToken> _buildPrecedingChordDragTarget(
    List<ContentToken> tokens,
    int position,
    String fontFamily,
    Color contentColor,
    Function(List<ContentToken>, ContentToken, int) onAddPrecedingChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
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
                return ChordToken(
                  token: candidateData.first!,
                  sectionColor: contentColor,
                  textStyle: TextStyle(
                    fontSize: _fontSize,
                    color: Colors.white,
                    fontFamily: fontFamily,
                  ),
                );
              } else {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      bottom: BorderSide(color: Colors.grey.shade400, width: 2),
                    ),
                  ),
                );
              }
            },
          )
        : DragTarget<ContentToken>(
            builder: (context, candidateData, rejectedData) {
              return SizedBox.shrink();
            },
          );
  }

  Widget _buildLyricDragTarget(
    List<ContentToken> tokens,
    ContentToken token,
    int position,
    Color contentColor,
    String fontFamily,
    Function(List<ContentToken>, ContentToken, int) onAddChord,
    Function(List<ContentToken>, int) onRemoveChord,
    bool isEnabled,
  ) {
    return isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onAddChord(tokens, details.data, position);
              if (details.data.position != null) {
                int index = details.data.position!;
                if (index > position) {
                  index += 1;
                }
                onRemoveChord(tokens, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      token.text,
                      style: TextStyle(
                        fontSize: _fontSize,
                        color: Colors.black87,
                        fontFamily: fontFamily,
                      ),
                    ),
                    Positioned(
                      top: -_fontSize,
                      child: ChordToken(
                        token: candidateData.first!,
                        sectionColor: contentColor,
                        textStyle: TextStyle(
                          fontSize: _fontSize,
                          color: Colors.white,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Text(
                token.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.black87,
                  fontFamily: fontFamily,
                ),
              );
            },
          )
        : Text(
            token.text,
            style: TextStyle(
              fontSize: _fontSize,
              color: Colors.black87,
              fontFamily: fontFamily,
            ),
          );
  }

  Widget _buildSpaceDragTarget(
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
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(width: width, height: 24),
                    Positioned(
                      top: -_fontSize,
                      child: ChordToken(
                        token: candidateData.first!,
                        sectionColor: contentColor,
                        textStyle: TextStyle(
                          fontSize: _fontSize,
                          color: Colors.white,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return SizedBox(width: width, height: 24);
            },
          )
        : SizedBox(width: width, height: 24);
  }
}
