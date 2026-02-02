import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_token.dart';
import 'package:cordis/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:flutter/material.dart';
import 'package:cordis/models/ui/content_token.dart';
import 'package:cordis/services/tokenization_service.dart';
import 'package:provider/provider.dart';

final double _fontSize = 18;

/// Helper class to track a widget along with its pre-calculated width
class _WidgetWithSize {
  final Widget widget;
  final double width;
  final TokenType type;

  _WidgetWithSize({
    required this.widget,
    required this.width,
    required this.type,
  });
}

class _ContentTokenized {
  final List<Widget> tokens;
  final double contentHeight;

  _ContentTokenized(this.tokens, this.contentHeight);
}

class TokenContentEditor extends StatefulWidget {
  final dynamic versionId;
  final String sectionCode;
  final bool isEnabled;

  const TokenContentEditor({
    super.key,
    required this.versionId,
    required this.sectionCode,
    this.isEnabled = true,
  });

  @override
  State<TokenContentEditor> createState() => _TokenContentEditorState();
}

class _TokenContentEditorState extends State<TokenContentEditor> {
  final TokenizationService _tokenizer = TokenizationService();

  bool _isDragging = false;

  bool _isEnabled(SelectionProvider selectionProvider) {
    if (!widget.isEnabled) return false;
    return !selectionProvider.isSelectionMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer3<
      SectionProvider,
      LayoutSettingsProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            sectionProvider,
            layoutSettingsProvider,
            selectionProvider,
            child,
          ) {
            final section = sectionProvider.getSection(
              widget.versionId,
              widget.sectionCode,
            )!;

            // Tokenize content text
            final tokens = _tokenizer.tokenize(section.contentText);

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: colorScheme.shadow, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    spacing: 8,
                    children: [
                      /// Drag Handle icon
                      Icon(
                        Icons.drag_indicator,
                        size: 32,
                        color: colorScheme.shadow,
                      ),

                      /// Section Code badge
                      Container(
                        height: 30,
                        width: 40,
                        decoration: BoxDecoration(
                          color: section.contentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            section.contentCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      /// Section Type label
                      Expanded(
                        child: Text(
                          section.contentType,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),

                      /// Delete icon (only visible when dragging)
                      _isDragging
                          ? DragTarget<ContentToken>(
                              onAcceptWithDetails: (details) => {
                                _removeChordAt(
                                  details.data.position!,
                                  sectionProvider,
                                  tokens,
                                ),
                              },
                              builder: (context, candidateData, rejectedData) {
                                if (candidateData.isNotEmpty) {
                                  return Icon(Icons.delete, color: Colors.red);
                                }
                                return Icon(Icons.delete, color: Colors.grey);
                              },
                            )
                          : const SizedBox.shrink(),

                      /// Edit Section button
                      _isEnabled(selectionProvider)
                          ? IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditSectionScreen(
                                      sectionCode: widget.sectionCode,
                                      versionId: widget.versionId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                            )
                          : SizedBox(height: 48),
                    ],
                  ),

                  Divider(height: 2, color: colorScheme.shadow),

                  /// CONTENT
                  Builder(
                    builder: (context) {
                      final content = _buildTokenWidgets(
                        context,
                        sectionProvider,
                        selectionProvider,
                        tokens,
                        layoutSettingsProvider.fontFamily,
                        section.contentColor,
                        lineSpacing: 8,
                        letterSpacing: 0,
                      );
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: content.contentHeight,
                          child: Stack(children: [...content.tokens]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
    );
  }

  /// Builds the list of positioned widgets, with token widgets as draggable and drag targets
  _ContentTokenized _buildTokenWidgets(
    BuildContext context,
    SectionProvider sectionProvider,
    SelectionProvider selectionProvider,
    List<ContentToken> tokens,
    String fontFamily,
    Color contentColor, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    List<Widget> tokenWidgets = [];
    double currentX = 0;
    double currentY = _fontSize;
    double chordOffsetX = 0;
    double chordY = 0;
    double maxWidth =
        MediaQuery.of(context).size.width -
        80; // Account for padding (16, 16, 8 left + 8, 16, 16 right)
    lineSpacing =
        lineSpacing + _fontSize; // To accomodate the chords above the lyrics

    // Track word widgets with their sizes to roll back if line break occurs
    List<_WidgetWithSize> wordWidgets = [];

    // Check if we need to add a preceding chord drag target at the start
    if (!_spaceBeforeLyric(0, tokens)) {
      tokenWidgets.add(
        Positioned(
          left: currentX,
          top: currentY,
          child: _buildPrecedingChordDragTarget(
            selectionProvider,
            0,
            sectionProvider,
            fontFamily,
            tokens,
            contentColor,
          ),
        ),
      );
      currentX += 24; // Width of the preceding chord drag target
    }

    // Build the widgets for each token
    int position = 0;
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          // Measure chord width (text + padding from ChordToken)
          final textPainter = TextPainter(
            text: TextSpan(
              text: token.text,
              style: TextStyle(fontSize: _fontSize, fontFamily: fontFamily),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          final chordWidth = textPainter.width + 8; // Add ChordToken padding

          // Save chord widget to be positioned once lyrics are positioned
          wordWidgets.add(
            _WidgetWithSize(
              widget: _buildDraggableChord(
                selectionProvider,
                token,
                position,
                contentColor,
                fontFamily,
              ),
              width: chordWidth,
              type: TokenType.chord,
            ),
          );
          break;

        case TokenType.lyric:
          // Measure the size of the token widget
          final textPainter = TextPainter(
            text: TextSpan(
              text: token.text,
              style: TextStyle(fontSize: _fontSize, fontFamily: fontFamily),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          final tokenWidth = textPainter.width;
          final tokenHeight = textPainter.height;

          // Check if adding this token exceeds the max width
          if (currentX + tokenWidth + letterSpacing > maxWidth) {
            // Move to next line
            currentX = 0;
            currentY += tokenHeight + lineSpacing;
            // Roll back word widgets, on the new line
            final positionedWordWidgets = _positionWordWidgets(
              wordWidgets,
              currentX,
              currentY,
              letterSpacing,
              0, // Reset chord offset on new line
              chordY,
            );
            tokenWidgets.addAll(positionedWordWidgets.$1);
            chordOffsetX = positionedWordWidgets.$2;
            chordY = positionedWordWidgets.$3;

            // Calculate offset to align the next token correctly (word offset is negative)
            currentX = -_calculateWordOffset(
              wordWidgets,
              currentX,
              letterSpacing,
            );

            wordWidgets.clear();
          }

          // Save token widget with its width, to be added once a space or newline is encountered
          wordWidgets.add(
            _WidgetWithSize(
              widget: _buildLyricDragTarget(
                token,
                position,
                sectionProvider,
                fontFamily,
                tokens,
                contentColor,
              ),
              width: tokenWidth,
              type: TokenType.lyric,
            ),
          );

          // Update currentX for next token
          currentX += tokenWidth + letterSpacing;
          break;

        case TokenType.space:
          // Calculate offsets before adding word widgets
          final wordOffsetX = _calculateWordOffset(
            wordWidgets,
            currentX,
            letterSpacing,
          );

          final positionedWordWidgets = _positionWordWidgets(
            wordWidgets,
            wordOffsetX,
            currentY,
            letterSpacing,
            chordOffsetX,
            chordY,
          );
          tokenWidgets.addAll(positionedWordWidgets.$1);
          chordOffsetX = positionedWordWidgets.$2;
          chordY = positionedWordWidgets.$3;
          wordWidgets.clear();

          // Measure the size of the space token widget
          final textPainter = TextPainter(
            text: TextSpan(
              text: ' ',
              style: TextStyle(fontSize: _fontSize, fontFamily: fontFamily),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          final tokenWidth = textPainter.width;

          // Check if adding the space token exceeds the max width
          if (currentX + tokenWidth + letterSpacing > maxWidth) {
            // Add space drag target at the end of the line
            tokenWidgets.add(
              Positioned(
                left: currentX,
                top: currentY,
                child: _buildSpaceDragTarget(
                  token,
                  tokens,
                  position,
                  maxWidth - currentX,
                  fontFamily,
                  sectionProvider,
                  contentColor,
                ),
              ),
            );

            // Move to next line
            currentX = 0;
            currentY += textPainter.height + lineSpacing;
          } else {
            // Position the space token widget
            tokenWidgets.add(
              Positioned(
                left: currentX,
                top: currentY,
                child: _buildSpaceDragTarget(
                  token,
                  tokens,
                  tokenWidgets.length + wordWidgets.length,
                  tokenWidth,
                  fontFamily,
                  sectionProvider,
                  contentColor,
                ),
              ),
            );
            // Update currentX for next token
            currentX +=
                tokenWidth + letterSpacing; // Add some horizontal spacing
          }
          break;

        case TokenType.newline:
          // Calculate offsets before adding word widgets
          final wordOffsetX = _calculateWordOffset(
            wordWidgets,
            currentX,
            letterSpacing,
          );
          final positionedWordWidgets = _positionWordWidgets(
            wordWidgets,
            wordOffsetX,
            currentY,
            letterSpacing,
            0,
            chordY,
          );
          tokenWidgets.addAll(positionedWordWidgets.$1);
          chordOffsetX = positionedWordWidgets.$2;
          chordY = positionedWordWidgets.$3;
          wordWidgets.clear();

          // Add space drag target that fills the rest of the line
          tokenWidgets.add(
            Positioned(
              left: currentX,
              top: currentY,
              child: _buildSpaceDragTarget(
                token,
                tokens,
                position,
                maxWidth - currentX,
                fontFamily,
                sectionProvider,
                contentColor,
              ),
            ),
          );

          // Move to next line
          currentX = 0;
          currentY += _fontSize + lineSpacing; // Add some vertical spacing

          // Check if we need to add a preceding chord drag target at the start of the next verse
          if (!_spaceBeforeLyric(
            tokenWidgets.length +
                wordWidgets.length +
                1, // Next token index after newline
            tokens,
          )) {
            tokenWidgets.add(
              Positioned(
                top: currentY,
                child: _buildPrecedingChordDragTarget(
                  selectionProvider,
                  tokenWidgets.length + wordWidgets.length + 1,
                  sectionProvider,
                  fontFamily,
                  tokens,
                  contentColor,
                ),
              ),
            );
            currentX += 24; // Width of the preceding chord drag target
          }
          break;
      }
      position++;
    }
    // Calculate offsets before adding word widgets
    final wordOffsetX = _calculateWordOffset(
      wordWidgets,
      currentX,
      letterSpacing,
    );

    final positionedWordWidgets = _positionWordWidgets(
      wordWidgets,
      wordOffsetX,
      currentY,
      letterSpacing,
      chordOffsetX,
      chordY,
    );
    tokenWidgets.addAll(positionedWordWidgets.$1);
    chordOffsetX = positionedWordWidgets.$2;
    chordY = positionedWordWidgets.$3;

    wordWidgets.clear();
    return _ContentTokenized(tokenWidgets, currentY + _fontSize + lineSpacing);
  }

  Widget _buildDraggableChord(
    SelectionProvider selectionProvider,
    ContentToken token,
    int position,
    Color contentColor,
    String fontFamily,
  ) {
    // Assign position to token for reference
    token.position = position;

    // GestureDetector to handle long press to drag transition
    return _isEnabled(selectionProvider)
        ? Draggable<ContentToken>(
            data: token,
            onDragStarted: _toggleDrag,
            onDragEnd: (details) => _toggleDrag(),
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
    SelectionProvider selectionProvider,
    int position,
    SectionProvider sectionProvider,
    String fontFamily,
    List<ContentToken> tokens,
    Color contentColor,
  ) {
    return _isEnabled(selectionProvider)
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              _addPrecedingChord(
                details.data,
                position,
                sectionProvider,
                tokens,
              );
              if (details.data.position != null) {
                int index = details.data.position!;
                if (index > position) {
                  index += 2; // Adjust for two insertions (Chord + Space)
                }
                _removeChordAt(index, sectionProvider, tokens);
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
    ContentToken token,
    int position,
    SectionProvider sectionProvider,
    String fontFamily,
    List<ContentToken> tokens,
    Color contentColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Container that contains the lyric drag target
    return DragTarget<ContentToken>(
      onAcceptWithDetails: (details) {
        _addChord(details.data, position, sectionProvider, tokens);
        if (details.data.position != null) {
          int index = details.data.position!;
          if (index > position) {
            index += 1;
          }
          _removeChordAt(index, sectionProvider, tokens);
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
                  color: colorScheme.onSurface,
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
            color: colorScheme.onSurface,
            fontFamily: fontFamily,
          ),
        );
      },
    );
  }

  Widget _buildSpaceDragTarget(
    ContentToken token,
    List<ContentToken> tokens,
    int position,
    double width,
    String fontFamily,
    SectionProvider sectionProvider,
    Color contentColor,
  ) {
    // Container that is sized to the lowest between space or remainder of the line
    return DragTarget<ContentToken>(
      onAcceptWithDetails: (details) {
        _addChord(details.data, position, sectionProvider, tokens);
        if (details.data.position != null) {
          int index = details.data.position!;
          if (index > position) {
            index++;
          }
          _removeChordAt(index, sectionProvider, tokens);
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
    );
  }

  /// Positions the word widgets at the given currentX and currentY
  /// Returns the list of positioned widgets along with last chord coords
  (List<Widget>, double, double) _positionWordWidgets(
    List<_WidgetWithSize> wordWidgets,
    double currentX,
    double currentY,
    double letterSpacing,
    double previousChordXOffset,
    double previousChordY,
  ) {
    List<Widget> positionedWidgets = [];
    double xOffset = currentX;
    double chordX = previousChordXOffset;
    double chordY = currentY - _fontSize;

    for (var widgetWithSize in wordWidgets) {
      // Position chords above lyrics, lyrics at baseline
      double xPos = xOffset;
      double yPos = currentY;
      if (widgetWithSize.type == TokenType.chord) {
        yPos = chordY;

        // Check if there is a preceding chord to offset
        if (xPos < chordX && previousChordY == chordY) {
          xPos = chordX;
        }
        chordX = xPos + widgetWithSize.width;
      }

      positionedWidgets.add(
        Positioned(left: xPos, top: yPos, child: widgetWithSize.widget),
      );

      // Update position based on pre-calculated width
      (widgetWithSize.type == TokenType.chord)
          ? xOffset +=
                0 // Chords do not take horizontal space
          : xOffset += widgetWithSize.width + letterSpacing;
    }
    return (positionedWidgets, chordX, chordY);
  }

  double _calculateWordOffset(
    List<_WidgetWithSize> wordWidgets,
    double currentX,
    double letterSpacing,
  ) {
    final wordOffsetX = wordWidgets.fold(currentX, (previousValue, element) {
      if (element.type == TokenType.chord) {
        return previousValue;
      } else {
        return previousValue - element.width + letterSpacing;
      }
    });
    return wordOffsetX;
  }

  void _toggleDrag() {
    setState(() {
      _isDragging = !_isDragging;
    });
  }

  void _notifyContentChanged(
    SectionProvider sectionProvider,
    List<ContentToken> tokens,
  ) {
    final newContent = _tokenizer.reconstructContent(
      tokens, // Exclude the last newline token
    );

    sectionProvider.cacheSection(
      widget.versionId,
      widget.sectionCode,
      newContentText: newContent,
    );
  }

  void _addChord(
    ContentToken token,
    int position,
    SectionProvider sectionProvider,
    List<ContentToken> tokens,
  ) {
    tokens.insert(position, token);
    _notifyContentChanged(sectionProvider, tokens);
  }

  void _addPrecedingChord(
    ContentToken token,
    int position,
    SectionProvider sectionProvider,
    List<ContentToken> tokens,
  ) {
    final emptySpaceToken = ContentToken(text: ' ', type: TokenType.space);
    final newToken = ContentToken(text: token.text, type: token.type);

    tokens.insert(position, emptySpaceToken);
    tokens.insert(position, newToken);

    _notifyContentChanged(sectionProvider, tokens);
  }

  void _removeChordAt(
    int position,
    SectionProvider sectionProvider,
    List<ContentToken> tokens,
  ) {
    tokens.removeAt(position);
    _notifyContentChanged(sectionProvider, tokens);
  }

  bool _spaceBeforeLyric(int position, List<ContentToken> tokens) {
    // Check if there is a preceding chord (space before lyrics)
    List<ContentToken> start = [];

    for (
      int i = position;
      (i < tokens.length && tokens[i].type != TokenType.lyric);
      i++
    ) {
      start.add(tokens[i]);
    }

    bool hasPrecedingChord = start.any(
      (token) => token.type == TokenType.space,
    );

    return hasPrecedingChord;
  }
}
