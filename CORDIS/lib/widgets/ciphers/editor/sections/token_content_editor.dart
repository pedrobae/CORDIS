import 'dart:math';

import 'package:cordis/models/domain/cipher/section.dart';
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
  final List<Positioned> tokens;
  final double contentHeight;

  _ContentTokenized(this.tokens, this.contentHeight);
}

/// Helper class to track positioned widgets with their associated _WidgetWithSize info
class _PositionedWithRef {
  final Positioned positioned;
  final _WidgetWithSize ref;

  _PositionedWithRef({required this.positioned, required this.ref});
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
  late List<ContentToken> tokens;
  late Section section;

  bool _isDragging = false;
  final Map<String, double> _widthCache = {};

  bool _isEnabled(SelectionProvider selectionProvider) {
    if (!widget.isEnabled) return false;
    return !selectionProvider.isSelectionMode;
  }

  /// Measures text width with caching to avoid recalculating TextPainter
  double _measureTextWidth(String text, String fontFamily) {
    final key = '$text|$fontFamily';
    return _widthCache.putIfAbsent(key, () {
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

  @override
  void initState() {
    super.initState();

    section = context.read<SectionProvider>().getSection(
      widget.versionId,
      widget.sectionCode,
    )!;
    tokens = _tokenizer.tokenize(section.contentText);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final newSection = context.read<SectionProvider>().getSection(
      widget.versionId,
      widget.sectionCode,
    )!;
    
    // Only setState if the section actually changed to avoid unnecessary rebuilds
    if (newSection.contentCode != section.contentCode || 
        newSection.contentText != section.contentText) {
      setState(() {
        section = newSection;
        tokens = _tokenizer.tokenize(section.contentText);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer2<
      LayoutSettingsProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            layoutSettingsProvider,
            selectionProvider,
            child,
          ) {
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
                                _removeChordAt(details.data.position!),
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
                      final widgetsWithSize = _buildTokenWidgets(
                        context,
                        tokens,
                        layoutSettingsProvider.fontFamily,
                        section.contentColor,
                        lineSpacing: 8,
                        letterSpacing: 0,
                      );
                      final content = _positionWidgets(widgetsWithSize);

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
  List<_WidgetWithSize> _buildTokenWidgets(
    BuildContext context,
    List<ContentToken> tokens,
    String fontFamily,
    Color contentColor, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    /// Build all token widgets, and calculate their sizes for positioning
    List<_WidgetWithSize> widgetsWithSize = [];
    int position = 0;
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.precedingChordTarget:
          widgetsWithSize.add(
            _WidgetWithSize(
              widget: _buildPrecedingChordDragTarget(
                position,
                fontFamily,
                tokens,
                contentColor,
              ),
              width: 24,
              type: TokenType.precedingChordTarget,
            ),
          );
          break;
        case TokenType.chord:
          final chordWidth =
              _measureTextWidth(token.text, fontFamily) +
              20; // Add ChordToken padding

          widgetsWithSize.add(
            _WidgetWithSize(
              widget: _buildDraggableChord(
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
          final lyricWidth = _measureTextWidth(token.text, fontFamily);

          widgetsWithSize.add(
            _WidgetWithSize(
              widget: _buildLyricDragTarget(
                token,
                position,
                contentColor,
                fontFamily,
              ),
              width: lyricWidth,
              type: TokenType.lyric,
            ),
          );
          break;

        case TokenType.space:
          final tokenWidth = _measureTextWidth(' ', fontFamily);

          widgetsWithSize.add(
            _WidgetWithSize(
              widget: _buildSpaceDragTarget(
                token,
                position,
                tokenWidth,
                fontFamily,
                contentColor,
              ),
              width: tokenWidth,
              type: TokenType.space,
            ),
          );
          break;

        case TokenType.newline:
          // Newline tokens dont have fixed width
          widgetsWithSize.add(
            _WidgetWithSize(
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

  _ContentTokenized _positionWidgets(
    List<_WidgetWithSize> widgetsWithSize, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    // Organize widgets by lines and words
    final wordWidgetsWithSize = <_WidgetWithSize>[];
    final lineWidgetsWithSize = <List<_WidgetWithSize>>[];
    final contentWidgetsWithSize = <List<List<_WidgetWithSize>>>[];
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
              // DO NOTHING FOR NOW, TODO - populate end of line with targets
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

    return _ContentTokenized(
      tokenWidgets,
      (viewLineIndex + 1) * // +1 to account for last line (index starts at 0)
          lineHeight,
    );
  }

  Widget _buildDraggableChord(
    ContentToken token,
    int position,
    Color contentColor,
    String fontFamily,
  ) {
    final selectionProvider = Provider.of<SelectionProvider>(context);

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
    int position,
    String fontFamily,
    List<ContentToken> tokens,
    Color contentColor,
  ) {
    final selectionProvider = Provider.of<SelectionProvider>(context);

    return _isEnabled(selectionProvider)
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              _addPrecedingChord(details.data, position);
              if (details.data.position != null) {
                int index = details.data.position!;
                if (index > position) {
                  index += 2; // Adjust for two insertions (Chord + Space)
                }
                _removeChordAt(index);
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
    Color contentColor,
    String fontFamily,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    // Container that contains the lyric drag target
    return DragTarget<ContentToken>(
      onAcceptWithDetails: (details) {
        _addChord(details.data, position);
        if (details.data.position != null) {
          int index = details.data.position!;
          if (index > position) {
            index += 1;
          }
          _removeChordAt(index);
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
    int position,
    double width,
    String fontFamily,
    Color contentColor,
  ) {
    // Container that is sized to the lowest between space or remainder of the line
    return DragTarget<ContentToken>(
      onAcceptWithDetails: (details) {
        _addChord(details.data, position);
        if (details.data.position != null) {
          int index = details.data.position!;
          if (index > position) {
            index++;
          }
          _removeChordAt(index);
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

  void _toggleDrag() {
    setState(() {
      _isDragging = !_isDragging;
    });
  }

  void _cacheChanges() {
    final newContent = _tokenizer.reconstructContent(
      tokens, // Excludes the last newline token
    );

    context.read<SectionProvider>().cacheSection(
      widget.versionId,
      widget.sectionCode,
      newContentText: newContent,
    );
  }

  void _addChord(ContentToken token, int position) {
    setState(() {
      tokens.insert(position, token);
    });
    _cacheChanges();
  }

  void _addPrecedingChord(ContentToken token, int position) {
    final emptySpaceToken = ContentToken(text: ' ', type: TokenType.space);
    final newToken = ContentToken(text: token.text, type: token.type);

    setState(() {
      tokens.insert(position, emptySpaceToken);
      tokens.insert(position, newToken);
    });
    _cacheChanges();
  }

  void _removeChordAt(int position) {
    setState(() {
      tokens.removeAt(position);
    });
    _cacheChanges();
  }
}
