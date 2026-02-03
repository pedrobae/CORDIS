// ignore_for_file: unused_local_variable
// TODO - Remove above line when _positionWidgetsWithSize is implemented

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
  late List<ContentToken> tokens;
  late Section section;

  bool _isDragging = false;

  bool _isEnabled(SelectionProvider selectionProvider) {
    if (!widget.isEnabled) return false;
    return !selectionProvider.isSelectionMode;
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      section = context.read<SectionProvider>().getSection(
        widget.versionId,
        widget.sectionCode,
      )!;
      tokens = _tokenizer.tokenize(section.contentText);
    });
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
                      final content = _positionWidgetsWithSize(widgetsWithSize);
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
        case TokenType.precedingChord:
          widgetsWithSize.add(
            _WidgetWithSize(
              widget: _buildPrecedingChordDragTarget(
                position,
                fontFamily,
                tokens,
                contentColor,
              ),
              width: 24,
              type: TokenType.precedingChord,
            ),
          );
          break;
        case TokenType.chord:
          final textPainter = TextPainter(
            text: TextSpan(
              text: token.text,
              style: TextStyle(fontSize: _fontSize, fontFamily: fontFamily),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          final chordWidth = textPainter.width + 20; // Add ChordToken padding

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
          // Measure the size of the token widget
          final textPainter = TextPainter(
            text: TextSpan(
              text: token.text,
              style: TextStyle(fontSize: _fontSize, fontFamily: fontFamily),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          widgetsWithSize.add(
            _WidgetWithSize(
              widget: _buildLyricDragTarget(
                token,
                position,
                contentColor,
                fontFamily,
              ),
              width: textPainter.width,
              type: TokenType.lyric,
            ),
          );
          break;

        case TokenType.space:
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

  _ContentTokenized _positionWidgetsWithSize(
    List<_WidgetWithSize> widgetsWithSize, {
    double lineSpacing = 8,
    double letterSpacing = 1,
  }) {
    int currentY = 0; // Line number
    double currentX = 0; // Current X position in line

    double chordX = 0;
    double chordY = 0;

    double maxWidth =
        MediaQuery.of(context).size.width -
        80; // Account for padding (16, 16, 8 left + 8, 16, 16 right)

    letterSpacing = letterSpacing;

    lineSpacing =
        lineSpacing + _fontSize; // To accomodate the chords above the lyrics

    final tokenWidgets = <Widget>[];

    // TODO - Iterate through widgets and position them

    return _ContentTokenized(tokenWidgets, currentY + _fontSize);
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
